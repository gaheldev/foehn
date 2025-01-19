import dplug.core.math : floor = fast_floor, abs = fast_fabs;
import std.algorithm : min, max;



nothrow @nogc:

struct Dsp
{
nothrow @nogc:

    float inputGain, outputGain;
    float effect, curve;
    bool clip, effectIn, bandSplit;
    // TODO: bandsplit


    void process(const(float*)[] inputs, float*[] outputs, int frames)
    {
        foreach (chan; 0..outputs.length)
            foreach (i; 0..frames)
            {
                float x = inputs[chan][i];
                if (effectIn)
                    outputs[chan][i] = x.gain(inputGain)
                                        .warp(clip)
                                        .waveshaper(curve)
                                        .mix(inputs[chan][i], 1.0-effect) // dry/wet
                                        .gain(outputGain);
                else
                    outputs[chan][i] = x.gain(inputGain); // bypass all effect and gain match
                // TODO: also bypass input?
            }
    }
}


float sign(float x)
{
    return x >= 0 ? 1 : -1;
}


float gain(float x, float linearGain)
{
    return x * linearGain;
}


float waveshaper(float x, float curve)
{
    return mix(wave1(x), wave2(x), curve);
}


/// 0 <= x <= 1
float wave1(float x)
{
    /* return 2*x - sign(x) * x^2; */
    return 2.0*x - x.sign*x^^2.0;
}


/// 0 <= x <= 1
float wave2(float x)
{
    return 1.5*x - x.sign*0.0625*x^^2 - 0.375*x^^3 - x.sign*0.0625*x^^4;
}


float warp(float x, bool clip)
{
    if (clip)
        return clipper(x);
    else
        return fold(x);
}


float clipper(float x)
{
    return min(max(x,-1), 1);
}


float fold(float x)
{
    float period = 4;
    return  2 * abs(2*((x+1)/period - floor((x+1)/period+0.5))) - 1;
}


/// amount in [0,1]
/// 0 -> x
/// 1 -> y
/// 0 <= amount <= 1
float mix(float x, float y, float amount)
{
    return y * amount + x * (1-amount);
}
