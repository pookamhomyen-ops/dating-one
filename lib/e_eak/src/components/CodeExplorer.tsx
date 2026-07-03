import React, { useState } from 'react';
import { DART_FILES, DartFile } from '../dartCodeData';

export const CodeExplorer: React.FC = () => {
  const [selectedFileIndex, setSelectedFileIndex] = useState(0);
  const [copySuccess, setCopySuccess] = useState(false);

  const currentFile = DART_FILES[selectedFileIndex];

  const handleCopyCode = () => {
    if (!currentFile) return;
    navigator.clipboard.writeText(currentFile.code);
    setCopySuccess(true);
    setTimeout(() => setCopySuccess(false), 2000);
  };

  return (
    <div className="bg-slate-950 rounded-xl border border-slate-800 h-full flex flex-col overflow-hidden text-slate-100">
      {/* Code Header Description */}
      <div className="bg-slate-900 p-4 border-b border-slate-800 flex flex-col md:flex-row justify-between items-start md:items-center gap-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="bg-cyan-500/10 text-cyan-400 text-xs px-2.5 py-1 rounded-full font-bold border border-cyan-500/20">
              Flutter + Flame + Forge2D
            </span>
            <span className="text-xs text-slate-400">ระบบฟิสิกส์และการชนสมบูรณ์แบบ (Self-contained)</span>
          </div>
          <p className="text-slate-300 text-xs mt-1.5 leading-relaxed">
            คุณสามารถคัดลอกไฟล์เหล่านี้ไปใส่ไว้ในโครงสร้างโฟลเดอร์ <code className="bg-slate-950 px-1.5 py-0.5 rounded text-yellow-400 text-[11px] font-mono">lib/kart_battle_game/</code> ในโปรเจกต์ Flutter ของคุณ เพื่อนำเกมไปฝังตัวรันในแอปจริงได้ทันที!
          </p>
        </div>
      </div>

      <div className="flex flex-1 flex-col lg:flex-row overflow-hidden">
        {/* Left Side: File Lists Navigator */}
        <div className="w-full lg:w-72 bg-slate-950 border-r border-slate-800 overflow-y-auto p-3 flex flex-col gap-1">
          <div className="text-slate-400 text-[10px] uppercase font-black tracking-wider px-2 py-1">
            โครงสร้างโฟลเดอร์โมดูลเกม (File Tree)
          </div>
          
          <div className="pl-2 flex flex-col gap-1 mb-4 text-slate-500 text-xs font-mono">
            <div>📂 lib/</div>
            <div className="pl-3">📂 kart_battle_game/</div>
          </div>

          <div className="text-slate-400 text-[10px] uppercase font-black tracking-wider px-2 py-1">
            เลือกไฟล์โค้ดของโมดูล
          </div>

          {DART_FILES.map((file, idx) => {
            const isSelected = idx === selectedFileIndex;
            return (
              <button
                key={file.path}
                onClick={() => {
                  setSelectedFileIndex(idx);
                  setCopySuccess(false);
                }}
                className={`w-full text-left px-3 py-2.5 rounded-lg text-xs font-medium transition-all flex flex-col gap-0.5 ${
                  isSelected
                    ? 'bg-yellow-500 text-slate-950 font-bold shadow-md shadow-yellow-500/10'
                    : 'text-slate-300 hover:bg-slate-900 hover:text-white'
                }`}
              >
                <div className="truncate flex items-center gap-1.5">
                  <span>📄</span>
                  <span className="truncate">{file.path.split('/').pop()}</span>
                </div>
                <div className={`text-[10px] truncate ${isSelected ? 'text-slate-800' : 'text-slate-500'}`}>
                  {file.name}
                </div>
              </button>
            );
          })}
        </div>

        {/* Right Side: Selected Code display */}
        <div className="flex-1 flex flex-col overflow-hidden bg-slate-900">
          {/* File path line and metadata */}
          <div className="bg-slate-950 px-5 py-3 border-b border-slate-800 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
            <div>
              <div className="text-yellow-400 font-mono text-xs font-bold truncate">
                📍 {currentFile.path}
              </div>
              <p className="text-slate-400 text-[11px] mt-1 leading-normal">
                {currentFile.description}
              </p>
            </div>

            <button
              onClick={handleCopyCode}
              className={`px-4 py-1.5 rounded-lg text-xs font-extrabold flex items-center gap-1.5 transition-all cursor-pointer ${
                copySuccess
                  ? 'bg-green-600 text-white shadow'
                  : 'bg-slate-800 hover:bg-slate-700 text-slate-200'
              }`}
            >
              {copySuccess ? (
                <>
                  <span>✓</span> คัดลอกสำเร็จ!
                </>
              ) : (
                <>
                  <span>📋</span> คัดลอกโค้ดไฟล์นี้
                </>
              )}
            </button>
          </div>

          {/* Source Code Container */}
          <div className="flex-1 overflow-auto p-5 font-mono text-xs leading-relaxed text-slate-300 selection:bg-yellow-500 selection:text-slate-950">
            <pre className="whitespace-pre">{currentFile.code}</pre>
          </div>
        </div>
      </div>
    </div>
  );
};
