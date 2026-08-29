import React from 'react';
import { Terminal, Signal, Clock, Server } from 'lucide-react';

export function LiveLogStream({ logs, activeAction }) {
  return (
    <div className="glass-panel rounded-2xl p-6 border border-slate-800 flex flex-col h-full">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold text-white flex items-center gap-2">
          <Terminal className="w-5 h-5 text-emerald-400" />
          سجل الأوامر المباشرة | Realtime Action Log Stream
        </h2>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 text-xs text-emerald-400 bg-emerald-950/60 px-2.5 py-1 rounded-full border border-emerald-500/30">
            <Signal className="w-3.5 h-3.5 animate-pulse" />
            <span className="font-mono">Sync latency: &lt;18ms</span>
          </div>
          <div className="flex items-center gap-1.5 text-xs text-cyan-400 bg-cyan-950/60 px-2.5 py-1 rounded-full border border-cyan-500/30">
            <Server className="w-3.5 h-3.5" />
            <span className="font-mono">RTDB Online</span>
          </div>
        </div>
      </div>

      {/* Active Payload Card */}
      {activeAction && (
        <div className="mb-4 p-4 rounded-xl bg-slate-900 border border-emerald-500/40">
          <div className="text-xs font-bold text-emerald-400 mb-2 flex items-center justify-between">
            <span className="flex items-center gap-1.5">
              <Clock className="w-3.5 h-3.5" />
              الأمر النشط حالياً في الملعب (CURRENT ACTIVE PAYLOAD)
            </span>
            <span className="font-mono text-[10px] text-slate-400">ID: {activeAction.action_id}</span>
          </div>
          <pre className="text-[11px] font-mono text-slate-300 bg-slate-950 p-3 rounded-lg overflow-x-auto max-h-36 border border-slate-800">
            {JSON.stringify(activeAction, null, 2)}
          </pre>
        </div>
      )}

      {/* Audit Log Stream */}
      <div className="flex-1 bg-slate-950 p-4 rounded-xl border border-slate-800 overflow-y-auto max-h-80 font-mono text-xs space-y-2">
        {logs.length === 0 ? (
          <div className="text-slate-600 text-center py-8 text-xs">
            لا توجد إشارات سابقة. اضغط على أي زر تفعيل في لوحة التحكم للبث.
          </div>
        ) : (
          logs.map((log, index) => (
            <div key={index} className="p-2.5 rounded bg-slate-900/80 border border-slate-850 text-slate-300">
              <div className="flex items-center justify-between text-[10px] text-slate-400 mb-1">
                <span className="text-emerald-400 font-bold">[{log.time}]</span>
                <span className="bg-slate-800 px-1.5 py-0.5 rounded text-slate-300 font-mono">{log.mode}</span>
              </div>
              <div className="text-slate-200 font-bold mb-1">{log.type} Target: {log.target_type} ({log.target_ids.length} Sectors)</div>
              <pre className="text-[10px] text-slate-400 overflow-x-auto">
                {JSON.stringify(log.payload, null, 1)}
              </pre>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
