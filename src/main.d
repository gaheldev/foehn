import std.math;
import dplug.core, dplug.client;

import dsp: Dsp;


// This define entry points for plugin formats, 
// depending on which version identifiers are defined.
mixin(pluginEntryPoints!Foehn);

enum : int
{
    paramInput,
    paramOutput,
    paramEffect,
    paramCurve,
    paramEffectIn,
    paramClip,
    paramBandSplit,
}


final class Foehn : Client
{
nothrow:
@nogc:
public:

    this()
    {
    }

    override PluginInfo buildPluginInfo()
    {
        // Plugin info is parsed from plugin.json here at compile time.
        // Indeed it is strongly recommended that you do not fill PluginInfo
        // manually, else the information could diverge.
        static immutable PluginInfo pluginInfo = parsePluginInfo(import("plugin.json"));
        return pluginInfo;
    }

    override Parameter[] buildParameters()
    {
        auto params = makeVec!Parameter();

        params ~= mallocNew!GainParameter(paramInput, "Input", 0.0, 12.0);
        params ~= mallocNew!GainParameter(paramOutput, "Output", 0.0, 0.0);

        params ~= mallocNew!LinearFloatParameter(paramEffect, "Effect", "%", 0.0, 100.0, 100);
        params ~= mallocNew!LinearFloatParameter(paramCurve, "Curve", "", -50.0, 50.0, 0.0);

        params ~= mallocNew!BoolParameter(paramEffectIn, "Effect In", true);
        params ~= mallocNew!BoolParameter(paramClip, "Clip", true);
        params ~= mallocNew!BoolParameter(paramBandSplit, "Band Split", false);

        return params.releaseData();
    }

    override LegalIO[] buildLegalIO()
    {
        auto io = makeVec!LegalIO();
        io ~= LegalIO(0, 1);
        io ~= LegalIO(0, 2);
        return io.releaseData();
    }

    override int maxFramesInProcess()
    {
        return 512; // samples only processed by a maximum of 32 samples
    }

    override void reset(double sampleRate, int maxFrames, int numInputs, int numOutputs)
    {
    }

    override void processAudio(const(float*)[] inputs, float*[] outputs, int frames, TimeInfo info)
    {
        _dsp.inputGain = convertDecibelToLinearGain(readParam!float(paramInput));
        _dsp.outputGain = convertDecibelToLinearGain(readParam!float(paramOutput));

        _dsp.effect = readParam!float(paramEffect);
        _dsp.curve = readParam!float(paramCurve);
        
        _dsp.effectIn = readParam!bool(paramEffectIn);
        _dsp.clip = readParam!bool(paramClip);
        _dsp.bandSplit = readParam!bool(paramBandSplit);


        _dsp.process(inputs, outputs, frames);
    }

private:
    Dsp _dsp;
}

