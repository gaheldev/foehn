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

    // carefull to add parameters in the same order as enum
    override Parameter[] buildParameters()
    {
        auto params = makeVec!Parameter();
        params ~= mallocNew!GainParameter(paramInput, "Input", 12.0, 0.0);
        params ~= mallocNew!GainParameter(paramOutput, "Output", 0.0, 0.0);
        params ~= mallocNew!LinearFloatParameter(paramEffect, "Effect", "%", 0.0, 100.0, 100.0);
        params ~= mallocNew!LinearFloatParameter(paramCurve, "Curve", "", -50.0, 50.0, 0.0);
        params ~= mallocNew!BoolParameter(paramEffectIn, "Effect In", true);
        params ~= mallocNew!BoolParameter(paramClip, "Clip", true);
        params ~= mallocNew!BoolParameter(paramBandSplit, "Band Split", false);
        return params.releaseData();
    }

    override LegalIO[] buildLegalIO()
    {
        auto io = makeVec!LegalIO();
        io ~= LegalIO(1, 1);
        io ~= LegalIO(2, 2);
        return io.releaseData();
    }

    // This override is optional, this supports plugin delay compensation in hosts.
    // By default, 0 samples of latency.
    override int latencySamples(double sampleRate) pure const 
    {
        return 0;
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


/* /// A parameter with [-inf to value] dB log mapping */
/* class GainParameter : FloatParameter */
/* { */
/*     this(int index, string name, double max, double defaultValue, double shape = 2.0) nothrow @nogc */
/*     { */
/*         super(index, name, "dB", -double.infinity, max, defaultValue); */
/*         _shape = shape; */
/*         setDecimalPrecision(1); */
/*     } */
/**/
/*     override double toNormalized(double value) */
/*     { */
/*         double maxAmplitude = convertDecibelToLinearGain(_max); */
/*         double result = ( convertDecibelToLinearGain(value) / maxAmplitude ) ^^ (1 / _shape); */
/*         if (result < 0) */
/*             result = 0; */
/*         if (result > 1) */
/*             result = 1; */
/*         assert(isFinite(result)); */
/*         return result; */
/*     } */
/**/
/*     override double fromNormalized(double normalizedValue) */
/*     { */
/*         return convertLinearGainToDecibel(  (normalizedValue ^^ _shape) * convertDecibelToLinearGain(_max)); */
/*     } */
/**/
/* private: */
/*     double _shape; */
/* } */

