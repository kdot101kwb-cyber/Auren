import React from "react";
import {AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig} from "remotion";

export type Scene = {heading: string; body: string};
export type VideoProps = {
  title: string;
  hook: string;
  scenes: Scene[];
  closing: string;
  brand?: string;
};

const bg = "#0b1020";
const accent = "#6ee7b7";
const white = "#f8fafc";

export const NovaVerticalVideo: React.FC<VideoProps> = ({
  title, hook, scenes, closing, brand = "NOVA",
}) => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  const sceneFrames = Math.max(1, Math.floor(durationInFrames / (scenes.length + 2)));
  const sceneIndex = Math.min(scenes.length - 1, Math.max(0, Math.floor((frame - sceneFrames) / sceneFrames)));
  const isHook = frame < sceneFrames;
  const isClosing = frame >= sceneFrames * (scenes.length + 1);
  const scene = scenes[sceneIndex] ?? {heading: title, body: hook};
  const opacity = interpolate(frame % sceneFrames, [0, 8, sceneFrames - 8, sceneFrames], [0, 1, 1, 0], {extrapolateLeft: "clamp", extrapolateRight: "clamp"});
  const translateY = interpolate(frame % sceneFrames, [0, 12], [28, 0], {extrapolateRight: "clamp"});
  const seconds = Math.floor(frame / fps);

  return (
    <AbsoluteFill style={{background: bg, color: white, fontFamily: "Arial, sans-serif", padding: 72, justifyContent: "space-between"}}>
      <div style={{display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 28, color: accent, fontWeight: 800}}>
        <span>{brand}</span><span>AI • IDEAS • ACTION</span>
      </div>
      <div style={{opacity: isHook || isClosing ? 1 : opacity, transform: `translateY(${isHook || isClosing ? 0 : translateY}px)`, display: "flex", flexDirection: "column", gap: 32}}>
        <div style={{fontSize: 24, letterSpacing: 4, color: accent, fontWeight: 700}}>
          {isHook ? "توقف لحظة" : isClosing ? "ابدأ اليوم" : `الفكرة ${sceneIndex + 1}`}
        </div>
        <div style={{fontSize: 72, lineHeight: 1.2, fontWeight: 900, overflowWrap: "anywhere"}}>
          {isHook ? hook : isClosing ? closing : scene.heading}
        </div>
        <div style={{fontSize: 38, lineHeight: 1.45, color: "#cbd5e1", overflowWrap: "anywhere"}}>
          {isHook ? title : isClosing ? "تابع NOVA للمزيد من الأفكار العملية" : scene.body}
        </div>
      </div>
      <div style={{display: "flex", flexDirection: "column", gap: 16}}>
        <div style={{height: 6, background: "#263047", borderRadius: 999, overflow: "hidden"}}>
          <div style={{width: `${Math.min(100, (frame / durationInFrames) * 100)}%`, height: "100%", background: accent}} />
        </div>
        <div style={{display: "flex", justifyContent: "space-between", color: "#94a3b8", fontSize: 22}}>
          <span>فيديو قصير • ${seconds}s</span><span>{brand}</span>
        </div>
      </div>
    </AbsoluteFill>
  );
};
