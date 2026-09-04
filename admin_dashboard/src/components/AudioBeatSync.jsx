import React, { useState, useEffect, useRef } from 'react';
import { Mic, MicOff, Music, Sliders, Activity, Zap, Play, Square, Volume2 } from 'lucide-react';

export function AudioBeatSync({ onTriggerAction, selectedSectors = [] }) {
  const [mode, setMode] = useState('MIC'); // 'MIC' | 'BPM'

  // Live Mic State
  const [isMicActive, setIsMicActive] = useState(false);
  const [volumeLevel, setVolumeLevel] = useState(0);
  const [sensitivity, setSensitivity] = useState(65); // 0 - 100
  const [micColor, setMicColor] = useState('#00E676');

  // Manual BPM State
  const [bpm, setBpm] = useState(120);
  const [isBpmActive, setIsBpmActive] = useState(false);
  const [bpmColor, setBpmColor] = useState('#00E5FF');

  // Audio Context Refs
  const audioCtxRef = useRef(null);
  const analyserRef = useRef(null);
  const streamRef = useRef(null);
  const animFrameRef = useRef(null);
  const lastBeatTimeRef = useRef(0);

  // BPM Interval Ref
  const bpmIntervalRef = useRef(null);

  // Stop Mic Cleanup
  const stopMic = () => {
    if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    if (audioCtxRef.current) {
      audioCtxRef.current.close();
      audioCtxRef.current = null;
    }
    setIsMicActive(false);
    setVolumeLevel(0);
  };

  // Start Live Mic Analyser
  const startMic = async () => {
    try {
      stopMic();
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;

      const AudioContext = window.AudioContext || window.webkitAudioContext;
      const audioCtx = new AudioContext();
      audioCtxRef.current = audioCtx;

      const analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      analyserRef.current = analyser;

      const source = audioCtx.createMediaStreamSource(stream);
      source.connect(analyser);

      setIsMicActive(true);
      analyzeAudio();
    } catch (err) {
      console.error('[AudioBeatSync] Microphone Access Error:', err);
      alert('⚠️ تعذر الوصول للميكروفون. يرجى السماح بتصريح الميكروفون في المتصفح.');
    }
  };

  // Analyze Audio Frequencies Loop
  const analyzeAudio = () => {
    if (!analyserRef.current) return;

    const bufferLength = analyserRef.current.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    const checkBeat = () => {
      if (!analyserRef.current) return;

      analyserRef.current.getByteFrequencyData(dataArray);

      // Focus on Bass Frequencies (Low bin range 0 to 10 for bass beats)
      let bassSum = 0;
      const bassBins = Math.min(12, bufferLength);
      for (let i = 0; i < bassBins; i++) {
        bassSum += dataArray[i];
      }
      const avgBass = bassSum / bassBins;
      const currentLevel = Math.min(100, Math.round((avgBass / 255) * 100));
      setVolumeLevel(currentLevel);

      // Trigger Beat Pulse if level exceeds sensitivity threshold and debounced (> 160ms)
      const now = Date.now();
      if (currentLevel >= sensitivity && now - lastBeatTimeRef.current > 160) {
        lastBeatTimeRef.current = now;
        onTriggerAction({
          type: 'STROBE',
          target_type: selectedSectors.length === 10 ? 'ALL' : 'SECTOR',
          target_ids: selectedSectors,
          color_hex: micColor,
          flash_frequency_ms: 100,
          duration_seconds: 1,
        });
      }

      animFrameRef.current = requestAnimationFrame(checkBeat);
    };

    checkBeat();
  };

  // Manual BPM Interval Logic
  useEffect(() => {
    if (isBpmActive) {
      const intervalMs = Math.round((60 / bpm) * 1000);
      bpmIntervalRef.current = setInterval(() => {
        onTriggerAction({
          type: 'STROBE',
          target_type: selectedSectors.length === 10 ? 'ALL' : 'SECTOR',
          target_ids: selectedSectors,
          color_hex: bpmColor,
          flash_frequency_ms: Math.min(150, Math.round(intervalMs / 2)),
          duration_seconds: 1,
        });
      }, intervalMs);
    } else {
      if (bpmIntervalRef.current) clearInterval(bpmIntervalRef.current);
    }

    return () => {
      if (bpmIntervalRef.current) clearInterval(bpmIntervalRef.current);
    };
  }, [isBpmActive, bpm, bpmColor, selectedSectors]);

  // Clean up on unmount
  useEffect(() => {
    return () => {
      stopMic();
      if (bpmIntervalRef.current) clearInterval(bpmIntervalRef.current);
    };
  }, []);

  return (
    <div className="space-y-6">
      {/* Header & Mode Switch */}
      <div className="flex flex-wrap items-center justify-between gap-4 bg-slate-900/90 p-4 rounded-xl border border-slate-800">
        <div>
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <Music className="w-4 h-4 text-cyan-400" />
            التفاعل مع الموسيقى والإيقاع | Music & Audio Beat Sync
          </h3>
          <p className="text-xs text-slate-400 mt-0.5">
            التقاط صوت الموسيقى عبر الميكروفون المباشر أو ضبط سرعة الإيقاع (BPM) لتوليد فلاشات متزامنة
          </p>
        </div>

        {/* Mode Selector */}
        <div className="flex items-center gap-2 bg-slate-950 p-1.5 rounded-xl border border-slate-800">
          <button
            onClick={() => {
              if (isBpmActive) setIsBpmActive(false);
              setMode('MIC');
            }}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
              mode === 'MIC'
                ? 'bg-cyan-500 text-black shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Mic className="w-3.5 h-3.5" />
            ميكروفون مباشر (Live Mic)
          </button>
          <button
            onClick={() => {
              if (isMicActive) stopMic();
              setMode('BPM');
            }}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition flex items-center gap-1.5 ${
              mode === 'BPM'
                ? 'bg-purple-500 text-white shadow'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            <Activity className="w-3.5 h-3.5" />
            إيقاع محدد (BPM Tempo)
          </button>
        </div>
      </div>

      {/* Live Mic Panel */}
      {mode === 'MIC' && (
        <div className="bg-slate-950/80 p-5 rounded-2xl border border-cyan-500/30 space-y-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <div
                className={`w-10 h-10 rounded-xl flex items-center justify-center transition ${
                  isMicActive
                    ? 'bg-cyan-500/20 text-cyan-400 border border-cyan-500/40 animate-pulse'
                    : 'bg-slate-900 text-slate-500 border border-slate-800'
                }`}
              >
                {isMicActive ? <Mic className="w-5 h-5" /> : <MicOff className="w-5 h-5" />}
              </div>
              <div>
                <div className="text-sm font-bold text-white">
                  {isMicActive ? 'الميكروفون متصل ويستمع للموسيقى 🎙️' : 'الميكروفون متوقف'}
                </div>
                <div className="text-xs text-slate-400">
                  {isMicActive
                    ? 'يتم تحليل ضربات الإيقاع (Bass Beats) وتوليد الفلاش أوتوماتيكياً'
                    : 'انقر على زر التشغيل لبدء الاستماع للموسيقى في الملعب'}
                </div>
              </div>
            </div>

            {isMicActive ? (
              <button
                onClick={stopMic}
                className="px-4 py-2.5 bg-red-950 hover:bg-red-900 border border-red-500/40 text-red-300 font-bold rounded-xl text-xs flex items-center gap-2 transition"
              >
                <Square className="w-4 h-4 fill-red-400" /> إيقاف الميكروفون
              </button>
            ) : (
              <button
                onClick={startMic}
                className="px-5 py-2.5 bg-cyan-500 hover:bg-cyan-400 text-black font-black rounded-xl text-xs flex items-center gap-2 transition shadow-lg shadow-cyan-500/20"
              >
                <Mic className="w-4 h-4" /> تشغيل الميكروفون المباشر
              </button>
            )}
          </div>

          {/* Visual Audio Spectrum & Sensitivity Controls */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-4 border-t border-slate-800">
            {/* Audio Volume Spectrum Meter */}
            <div>
              <div className="flex items-center justify-between text-xs text-slate-300 mb-2 font-bold">
                <span className="flex items-center gap-1">
                  <Volume2 className="w-4 h-4 text-cyan-400" /> مستوى صوت الميكروفون المباشر:
                </span>
                <span className="font-mono text-cyan-400">{volumeLevel}%</span>
              </div>

              {/* Progress Level Bar */}
              <div className="relative w-full h-8 bg-slate-900 rounded-xl overflow-hidden border border-slate-800 p-1">
                {/* Sensitivity Threshold Line Marker */}
                <div
                  className="absolute top-0 bottom-0 w-0.5 bg-amber-400 z-20 shadow-md"
                  style={{ left: `${sensitivity}%` }}
                  title={`عتبة الحساسية: ${sensitivity}%`}
                />
                <div
                  className="h-full rounded-lg transition-all duration-75 bg-gradient-to-r from-emerald-500 via-cyan-400 to-amber-400"
                  style={{ width: `${volumeLevel}%` }}
                />
              </div>
              <div className="text-[10px] text-amber-400 mt-1 flex justify-between">
                <span>0%</span>
                <span>الخط الأصفر = عتبة إطلاق الفلاش ({sensitivity}%)</span>
                <span>100%</span>
              </div>
            </div>

            {/* Controls */}
            <div className="space-y-4">
              <div>
                <label className="text-xs text-slate-400 block mb-1 font-bold">
                  حساسية التقاط الإيقاع / Sensitivity ({sensitivity}%)
                </label>
                <input
                  type="range"
                  min="20"
                  max="95"
                  value={sensitivity}
                  onChange={(e) => setSensitivity(Number(e.target.value))}
                  className="w-full accent-cyan-500"
                />
              </div>

              <div>
                <label className="text-xs text-slate-400 block mb-1 font-bold">
                  لون فلاش الإيقاع / Beat Color
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="color"
                    value={micColor}
                    onChange={(e) => setMicColor(e.target.value)}
                    className="w-9 h-9 rounded bg-slate-900 border border-slate-700 cursor-pointer"
                  />
                  <input
                    type="text"
                    value={micColor}
                    onChange={(e) => setMicColor(e.target.value)}
                    className="bg-slate-900 border border-slate-800 rounded px-3 py-1.5 text-xs text-white flex-1"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Manual BPM Panel */}
      {mode === 'BPM' && (
        <div className="bg-slate-950/80 p-5 rounded-2xl border border-purple-500/30 space-y-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div>
              <div className="text-sm font-bold text-white">ضبط معدل الإيقاع المخصص (BPM Tempo)</div>
              <div className="text-xs text-slate-400">
                حدد عدد الضربات في الدقيقة (Beats Per Minute) لتوليد ومضات فلاش منتظمة مع الأغنية
              </div>
            </div>

            {isBpmActive ? (
              <button
                onClick={() => setIsBpmActive(false)}
                className="px-4 py-2.5 bg-red-950 hover:bg-red-900 border border-red-500/40 text-red-300 font-bold rounded-xl text-xs flex items-center gap-2 transition"
              >
                <Square className="w-4 h-4 fill-red-400" /> إيقاف الإيقاع
              </button>
            ) : (
              <button
                onClick={() => setIsBpmActive(true)}
                className="px-5 py-2.5 bg-purple-500 hover:bg-purple-400 text-white font-black rounded-xl text-xs flex items-center gap-2 transition shadow-lg shadow-purple-500/20"
              >
                <Play className="w-4 h-4 fill-white" /> بدء الوميض التزامني ({bpm} BPM)
              </button>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-4 border-t border-slate-800">
            <div>
              <label className="text-xs text-slate-400 block mb-1 font-bold">
                سرعة الإيقاع / Tempo ({bpm} BPM)
              </label>
              <input
                type="range"
                min="60"
                max="180"
                step="2"
                value={bpm}
                onChange={(e) => setBpm(Number(e.target.value))}
                className="w-full accent-purple-500"
              />

              {/* Quick BPM Presets */}
              <div className="flex items-center gap-2 mt-3">
                <span className="text-[11px] text-slate-400 font-bold">سرعات شائعة:</span>
                {[
                  { label: 'بطيء 90', val: 90 },
                  { label: 'عادي 120', val: 120 },
                  { label: 'حماسي 140', val: 140 },
                  { label: 'سريع 160', val: 160 },
                ].map((preset) => (
                  <button
                    key={preset.val}
                    onClick={() => setBpm(preset.val)}
                    className="px-2.5 py-1 rounded bg-slate-900 hover:bg-slate-800 text-purple-300 border border-purple-500/30 text-[11px] font-bold"
                  >
                    {preset.label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="text-xs text-slate-400 block mb-1 font-bold">
                لون الفلاش التزامني / Color HEX
              </label>
              <div className="flex items-center gap-2">
                <input
                  type="color"
                  value={bpmColor}
                  onChange={(e) => setBpmColor(e.target.value)}
                  className="w-9 h-9 rounded bg-slate-900 border border-slate-700 cursor-pointer"
                />
                <input
                  type="text"
                  value={bpmColor}
                  onChange={(e) => setBpmColor(e.target.value)}
                  className="bg-slate-900 border border-slate-800 rounded px-3 py-1.5 text-xs text-white flex-1"
                />
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
