package com.elbadev.sound_check;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.util.Log;

public class ToneGenerator {

    private static final String LOG_TAG = ToneGenerator.class.getSimpleName();

    private Thread mThread;
    private short[] mBuffer;
    private AudioTrack mAudioTrack;
    private AudioStreamLooper looper;
    private boolean shouldPlay = false;
    private int mBufferSize;

    public void setFrequency(double v){
        looper.setFrequency(v);
    }

    public void setWaveform(String v){
        int waveformIndex = 0;

        if(v.equals("sawTooth")) waveformIndex = 1;
        else if(v.equals("square")) waveformIndex = 2;
        looper.setWaveformIndex(waveformIndex);
    }

    /**
     *
     */
    public ToneGenerator(){
        looper = new AudioStreamLooper();
        initAudioTrack();
    }

    // -------- privs

    private void initAudioTrack(){

        mBufferSize = AudioTrack.getMinBufferSize(
                AudioStreamLooper.SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_8BIT);

        mAudioTrack = new AudioTrack(
                AudioManager.STREAM_MUSIC,
                AudioStreamLooper.SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                mBufferSize,
                AudioTrack.MODE_STREAM);

        Log.v(LOG_TAG, "mBufferSize: " +Integer.toString(mBufferSize));

        looper.setBufferSize(mBufferSize);
    }

    private synchronized void resumePlay(){
        try {
            wait(500);
            play();
        }
        catch (Exception e){
            Log.v(LOG_TAG, "error waiting process: " +e.toString());
        }
    }

    private void play(){

        Log.v(LOG_TAG, "starting tone");
        looper.reset();

        while (shouldPlay) {
            short[] buffer = looper.getSampleBuffer();

            for(int i = 0; i < mBufferSize; i++){
                mAudioTrack.write(buffer, i, 1);
            }
        }
    }

    // -------- publics

    public boolean playing() {
        return mThread != null;
    }

    public void startPlayback(){
        if (mThread != null || mAudioTrack.getState() != AudioTrack.STATE_INITIALIZED) return;

        mAudioTrack.flush();

        // Start streaming in a thread
        shouldPlay = true;
        mThread = new Thread(new Runnable() {
            @Override
            public void run() {
                play();
            }
        });

        mThread.start();
        mAudioTrack.play();
    }

    public void stopPlayback() {

        if (mThread == null) return;

        shouldPlay = false;
        mThread = null;

        mAudioTrack.pause();  // pause() stops the playback immediately.
        mAudioTrack.stop();   // Unblock mAudioTrack.write() to avoid deadlocks.
        mAudioTrack.flush();  // just in case...
    }

    public Boolean stopIfPlaying(){

        if (playing()) {
            stopPlayback();
            return true;
        }

        return false;
    }

    public void release() {
        mAudioTrack.release();
    }

} // endof klazz