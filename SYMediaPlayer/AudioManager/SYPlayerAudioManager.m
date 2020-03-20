//
//  SYPlayerAudioManager.m
//  SYMediaPlayer
//
//  Created by RYB_iMAC on 2020/3/17.
//  Copyright © 2020 RYB. All rights reserved.
//

#import "SYPlayerAudioManager.h"
#import <Accelerate/Accelerate.h>
#import <AVFoundation/AVFoundation.h>


@interface SYPlayerAudioManager ()
{
    float * _outData;
    
    AUGraph _graph;
    AUNode _mixerNode;
    AUNode _outputNode;
    AUNode _timePitchNode;
    AudioUnit _mixerUnit;
    AudioUnit _outputUnit;
    AudioUnit _timePitchUnit;
}

@property (nonatomic, readonly) BOOL needsTimePitchNode;
@property (nonatomic, strong) AVAudioSession * audioSession;

@end


@implementation SYPlayerAudioManager

- (instancetype)init
{
    if (self = [super init])
    {
        int max_chan = 2;
        int max_frame_size = 4096;
        self->_outData = (float *)calloc(max_frame_size * max_chan, sizeof(float));
        
        [self setupAudioUnit];
    }
    return self;
}

- (void)dealloc
{
    AUGraphStop(_graph);
    AUGraphUninitialize(_graph);
    AUGraphClose(_graph);
    DisposeAUGraph(_graph);
    
    if (self->_outData) {
        free(self->_outData);
        self->_outData = NULL;
    }
    
    NSLog(@"SYPlayerAudioManager dealloc");
}


#pragma mark - Setup

- (BOOL)setupAudioUnit
{
    self.audioSession = [AVAudioSession sharedInstance];
    
    //.
    AudioComponentDescription mixerDescription;
    mixerDescription.componentType = kAudioUnitType_Mixer;
    mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //.
    AudioComponentDescription outputDescription;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //.
    AudioComponentDescription pitchDescription;
    pitchDescription.componentType = kAudioUnitType_FormatConverter;
    pitchDescription.componentSubType = kAudioUnitSubType_NewTimePitch;
    pitchDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    //. Create graph, Add node
    NewAUGraph(&_graph);
    AUGraphAddNode(_graph, &mixerDescription, &_mixerNode);
    AUGraphAddNode(_graph, &outputDescription, &_outputNode);
    AUGraphAddNode(_graph, &pitchDescription, &_timePitchNode);
    
    //. Open graph, Node info
    AUGraphOpen(_graph);
    AUGraphNodeInfo(_graph, _mixerNode, &mixerDescription, &_mixerUnit);
    AUGraphNodeInfo(_graph, _outputNode, &outputDescription, &_outputUnit);
    AUGraphNodeInfo(_graph, _timePitchNode, &pitchDescription, &_timePitchUnit);
    
    //. Set property
    UInt32 value = 4096;
    UInt32 size = sizeof(value);
    AudioUnitScope scope = kAudioUnitScope_Global;
    AudioUnitPropertyID param = kAudioUnitProperty_MaximumFramesPerSlice;
    AudioUnitSetProperty(_mixerUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_outputUnit, param, scope, 0, &value, size);
    AudioUnitSetProperty(_timePitchUnit, param, scope, 0, &value, size);
    
    //. Callback
    AURenderCallbackStruct inputCallbackStruct;
    inputCallbackStruct.inputProc = inputCallback;
    inputCallbackStruct.inputProcRefCon = (__bridge void *)(self);
    AUGraphSetNodeInputCallback(_graph, _mixerNode, 0, &inputCallbackStruct);
    AudioUnitAddRenderNotify(_outputUnit, outputCallback, (__bridge void *)self);
    
    //. Get parameter
    AudioUnitParameterID mixerParam = kMultiChannelMixerParam_Volume;
    AudioUnitGetParameter(_mixerUnit, mixerParam, kAudioUnitScope_Input, 0, &_volume);
    AudioUnitGetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, &_rate);
    AudioUnitGetParameter(_timePitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, &_pitch);
    
    //.
    AudioStreamBasicDescription asbd;
    UInt32 byteSize = sizeof(float);
    asbd.mBitsPerChannel   = byteSize * 8;
    asbd.mBytesPerFrame    = byteSize;
    asbd.mChannelsPerFrame = 2;
    asbd.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    asbd.mFormatID         = kAudioFormatLinearPCM;
    asbd.mFramesPerPacket  = 1;
    asbd.mBytesPerPacket   = asbd.mFramesPerPacket * asbd.mBytesPerFrame;
    asbd.mSampleRate       = 44100.0f;
    
    UInt32 streamSize = sizeof(AudioStreamBasicDescription);
    AudioUnitPropertyID audioParam = kAudioUnitProperty_StreamFormat;
    if (AudioUnitSetProperty(_mixerUnit, audioParam, kAudioUnitScope_Input, 0, &asbd, streamSize) == noErr &&
        AudioUnitSetProperty(_mixerUnit, audioParam, kAudioUnitScope_Output, 0, &asbd, streamSize) == noErr &&
        AudioUnitSetProperty(_outputUnit, audioParam, kAudioUnitScope_Input, 0, &asbd, streamSize) == noErr &&
        AudioUnitSetProperty(_timePitchUnit, audioParam, kAudioUnitScope_Input, 0, &asbd, streamSize) == noErr &&
        AudioUnitSetProperty(_timePitchUnit, audioParam, kAudioUnitScope_Output, 0, &asbd, streamSize) == noErr) {
        _asbd = asbd;
    }
    else {
        AudioUnitSetProperty(_mixerUnit, audioParam, kAudioUnitScope_Input, 0, &_asbd, streamSize);
        AudioUnitSetProperty(_mixerUnit, audioParam, kAudioUnitScope_Output, 0, &_asbd, streamSize);
        AudioUnitSetProperty(_outputUnit, audioParam, kAudioUnitScope_Input, 0, &_asbd, streamSize);
        AudioUnitSetProperty(_timePitchUnit, audioParam, kAudioUnitScope_Input, 0, &_asbd, streamSize);
        AudioUnitSetProperty(_timePitchUnit, audioParam, kAudioUnitScope_Output, 0, &_asbd, streamSize);
    }
    
    //.
    [self reconnectTimePitchNodeForce:YES];
    
    //.
    AUGraphInitialize(_graph);
    
    return YES;
}

- (void)disconnectNodeInput:(AUNode)sourceNode destNode:(AUNode)destNode
{
    UInt32 count = 8;
    AUNodeInteraction interactions[8];
    if (AUGraphGetNodeInteractions(_graph, destNode, &count, interactions) == noErr) {
        for (UInt32 i = 0; i < MIN(count, 8); i++) {
            AUNodeInteraction interaction = interactions[i];
            if (interaction.nodeInteractionType == kAUNodeInteraction_Connection) {
                AUNodeConnection connection = interaction.nodeInteraction.connection;
                if (connection.sourceNode == sourceNode) {
                    AUGraphDisconnectNodeInput(_graph, connection.destNode, connection.destInputNumber);
                    break;
                }
            }
        }
    }
}

- (void)reconnectTimePitchNodeForce:(BOOL)force
{
    BOOL needsTimePitchNode = (_rate != 1.0) || (_pitch != 0.0);
    if (_needsTimePitchNode != needsTimePitchNode || force) {
        _needsTimePitchNode = needsTimePitchNode;
        if (needsTimePitchNode) {
            [self disconnectNodeInput:_mixerNode destNode:_outputNode];
            AUGraphConnectNodeInput(_graph, _mixerNode, 0, _timePitchNode, 0);
            AUGraphConnectNodeInput(_graph, _timePitchNode, 0, _outputNode, 0);
        } else {
            [self disconnectNodeInput:_mixerNode destNode:_timePitchNode];
            [self disconnectNodeInput:_timePitchNode destNode:_outputNode];
            AUGraphConnectNodeInput(_graph, _mixerNode, 0, _outputNode, 0);
        }
        AUGraphUpdate(_graph, NULL);
    }
}


#pragma mark - Interface

- (void)playWithDelegate:(id<SYPlayerAudioManagerDelegate>)delegate
{
    self->_delegate = delegate;
    [self play];
}

- (BOOL)isPlaying
{
    Boolean ret = FALSE;
    AUGraphIsRunning(_graph, &ret);
    return (ret == TRUE ? YES : NO);
}

- (void)play
{
    if (![self isPlaying]) {
        AUGraphStart(_graph);
    }
}

- (void)pause
{
    if ([self isPlaying]) {
        AUGraphStop(_graph);
    }
}

- (void)flush
{
    AudioUnitReset(_mixerUnit, kAudioUnitScope_Global, 0);
    AudioUnitReset(_outputUnit, kAudioUnitScope_Global, 0);
    AudioUnitReset(_timePitchUnit, kAudioUnitScope_Global, 0);
}


#pragma mark - Setter & Getter

- (void)setRate:(float)rate
{
    if (_rate == rate) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Rate, kAudioUnitScope_Global, 0, rate, 0) == noErr) {
        _rate = rate;
        [self reconnectTimePitchNodeForce:NO];
    }
}

- (void)setPitch:(float)pitch
{
    if (_pitch == pitch) {
        return;
    }
    if (AudioUnitSetParameter(_timePitchUnit, kNewTimePitchParam_Pitch, kAudioUnitScope_Global, 0, pitch, 0) == noErr) {
        _pitch = pitch;
        [self reconnectTimePitchNodeForce:NO];
    }
}

- (void)setVolume:(float)volume
{
    if (_volume == volume) {
        return;
    }
    AudioUnitParameterID param = kMultiChannelMixerParam_Volume;
    if (AudioUnitSetParameter(_mixerUnit, param, kAudioUnitScope_Input, 0, volume, 0) == noErr) {
        _volume = volume;
    }
}

- (Float64)samplingRate
{
    Float64 number = self.asbd.mSampleRate;
    if (number > 0) {
        return number;
    }
    return (Float64)self.audioSession.sampleRate;
}

- (UInt32)numberOfChannels
{
    UInt32 number = self.asbd.mChannelsPerFrame;
    if (number > 0) {
        return number;
    }
    return (UInt32)self.audioSession.outputNumberOfChannels;
}


#pragma mark - Callback

static OSStatus inputCallback(void * inRefCon,
                               AudioUnitRenderActionFlags * ioActionFlags,
                               const AudioTimeStamp * inTimeStamp,
                               UInt32 inOutputBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList * ioData)
{
    SYPlayerAudioManager * manager = (__bridge SYPlayerAudioManager *)inRefCon;
    [manager renderFrames:inNumberFrames ioData:ioData];
    return noErr;
}

static OSStatus outputCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData)
{
    @autoreleasepool {
        SYPlayerAudioManager *self = (__bridge SYPlayerAudioManager *)inRefCon;
        if ((*ioActionFlags) & kAudioUnitRenderAction_PreRender) {
            if ([self.delegate respondsToSelector:@selector(audioPlayer:willRender:)]) {
                [self.delegate audioPlayer:self willRender:inTimeStamp];
            }
        }
        else if ((*ioActionFlags) & kAudioUnitRenderAction_PostRender) {
            if ([self.delegate respondsToSelector:@selector(audioPlayer:didRender:)]) {
                [self.delegate audioPlayer:self didRender:inTimeStamp];
            }
        }
    }
    return noErr;
}

- (void)renderFrames:(UInt32)numberOfFrames ioData:(AudioBufferList *)ioData
{
    @autoreleasepool {
        for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
            memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
        }
        
        if ([self isPlaying] && self.delegate)
        {
            [self.delegate audioManager:self outputData:self->_outData
                         numberOfFrames:numberOfFrames numberOfChannels:self.numberOfChannels];
            
            UInt32 numBytesPerSample = self.asbd.mBitsPerChannel / 8;
            if (numBytesPerSample == 4) {
                float scalar = 0;
                for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                    int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                    for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                        vDSP_vsadd(self->_outData + iBuffer + iChannel, self.numberOfChannels,
                                   &scalar, (float *)ioData->mBuffers[iBuffer].mData + iChannel,
                                   thisNumChannels, numberOfFrames);
                    }
                }
            }
            else if (numBytesPerSample == 2)
            {
                float scalar = INT16_MAX;
                vDSP_vsmul(self->_outData, 1, &scalar, self->_outData, 1, numberOfFrames * self.numberOfChannels);
                
                for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; iBuffer++) {
                    int thisNumChannels = ioData->mBuffers[iBuffer].mNumberChannels;
                    for (int iChannel = 0; iChannel < thisNumChannels; iChannel++) {
                        vDSP_vfix16(self->_outData + iBuffer + iChannel, self.numberOfChannels,
                                    (SInt16 *)ioData->mBuffers[iBuffer].mData + iChannel,
                                    thisNumChannels, numberOfFrames);
                    }
                }
            }
        }
    }
}
@end
