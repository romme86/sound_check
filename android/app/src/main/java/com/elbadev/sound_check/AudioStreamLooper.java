package com.elbadev.sound_check;

public class AudioStreamLooper {

    private static final String LOG_TAG = AudioStreamLooper.class.getSimpleName();

    // NOTE: this is hardcoded for simplicity,
    // you should get this value from AudioManager since it's device dependent
    public static final int SAMPLE_RATE = 44100;
    public static final int CHANNELS = 1;

    private static final double K = 2.0 * Math.PI / SAMPLE_RATE;

    private double f;
    private double l = 0.0;
    private double q = 0.0;

    private double _frequency = 440.0;
    private int _bufferSize = 8192;
    private int _waveformIndex = 0; // 0 sine, 1 saw, 2 square

    public void setBufferSize(int v){
        _bufferSize = v;
    }

    public void setFrequency(double v){
        _frequency = v;
    }
    public void setWaveformIndex(int v){
        _waveformIndex = v;
    }
    public int getWaveformIndex(){
        return _waveformIndex;
    }

    /**
     *
     */
    public AudioStreamLooper(){
        resetCounters();
    }

    // -------------- privs

    private void resetCounters(){
        f = _frequency;
        l = 0.0;
        q = 0.0;
    }

    private void updateCounters(){
        f += (_frequency - f) / 4096.0;
        l += (16384.0 - l) / 4096.0;
        q += (q < Math.PI) ? f * K : (f * K) - (2.0 * Math.PI);
    }

    private short genSineSample(){
        return (short) Math.round(Math.sin(q) * l);
    }
    private short genSawSample(){
        return  (short) Math.round((q / Math.PI) * l);
    }
    private short genSquareSample(){ return (short) ((q > 0.0) ? l : -l); }

    // -------------- publics

    public void reset(){
        resetCounters();
    }

    public short[] getSampleBuffer(){
        short[] sampleBuffer = new short[_bufferSize];

        for(int i = 0; i < _bufferSize; i++){
            updateCounters();

            if(_waveformIndex == 0) sampleBuffer[i] = genSineSample();
            else if(_waveformIndex == 1) sampleBuffer[i] = genSawSample();
            else if(_waveformIndex == 2) sampleBuffer[i] = genSquareSample();
        }

        return sampleBuffer;
    }
}