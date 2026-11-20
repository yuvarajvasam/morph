import React, { useState } from "react";
import { Form, ActionPanel, Action, showToast, Toast, open } from "@raycast/api";
import { convertVideo, extractAudio, inspectFile, MorphFileInfo, MorphConversionResult } from "./morph-bridge";

export default function Command() {
  const [selectedFile, setSelectedFile] = useState<string>("");
  const [mode, setMode] = useState<"video" | "gif" | "audio">("video");
  const [targetFormat, setTargetFormat] = useState<string>("mp4");
  const [fps, setFps] = useState<string>("15");
  const [fileInfo, setFileInfo] = useState<MorphFileInfo | null>(null);
  const [result, setResult] = useState<MorphConversionResult | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function handleFileChange(paths: string[]) {
    if (paths.length === 0) return;
    const path = paths[0];
    setSelectedFile(path);
    try {
      const info = await inspectFile(path);
      setFileInfo(info);
    } catch {
      showToast({ style: Toast.Style.Failure, title: "Failed to inspect file" });
    }
  }

  async function handleSubmit() {
    if (!selectedFile) {
      await showToast({ style: Toast.Style.Failure, title: "Please choose a media file" });
      return;
    }

    setIsLoading(true);
    const toast = await showToast({
      style: Toast.Style.Animated,
      title: mode === "audio" ? "Extracting / Converting Audio..." : mode === "gif" ? "Generating Animated GIF..." : `Converting Video to ${targetFormat.toUpperCase()}...`
    });

    try {
      let res: MorphConversionResult;
      if (mode === "audio") {
        res = await extractAudio(selectedFile, targetFormat);
      } else if (mode === "gif") {
        res = await convertVideo(selectedFile, "gif", { toGif: true, fps: parseInt(fps, 10) || 15 });
      } else {
        res = await convertVideo(selectedFile, targetFormat);
      }
      setResult(res);
      setIsLoading(false);
      toast.style = Toast.Style.Success;
      toast.title = "Media conversion complete!";
    } catch (err: any) {
      setIsLoading(false);
      toast.style = Toast.Style.Failure;
      toast.title = "Conversion failed";
      toast.message = String(err);
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Convert with FFmpeg" onSubmit={handleSubmit} />
          {result?.outputs[0] && (
            <Action title="Open Converted File" onAction={() => open(result.outputs[0])} />
          )}
        </ActionPanel>
      }
    >
      <Form.FilePicker
        id="files"
        title="Select Media File"
        canChooseDirectories={false}
        onChange={handleFileChange}
      />

      {fileInfo && (
        <Form.Description
          title="Source File"
          text={`${fileInfo.filename} (${fileInfo.formattedSize})`}
        />
      )}

      <Form.Dropdown id="mode" title="Operation" value={mode} onChange={(v) => {
        setMode(v as any);
        if (v === "audio") setTargetFormat("mp3");
        else if (v === "video") setTargetFormat("mp4");
        else if (v === "gif") setTargetFormat("gif");
      }}>
        <Form.Dropdown.Item value="video" title="Convert Video (MP4, MOV, WebM, MKV)" />
        <Form.Dropdown.Item value="gif" title="Convert Video to Animated GIF" />
        <Form.Dropdown.Item value="audio" title="Extract / Convert Audio (MP3, WAV, M4A)" />
      </Form.Dropdown>

      {mode === "video" && (
        <Form.Dropdown id="videoFormat" title="Target Video Format" value={targetFormat} onChange={setTargetFormat}>
          <Form.Dropdown.Item value="mp4" title="MP4 (H.264 / AAC — High Compatibility)" />
          <Form.Dropdown.Item value="mov" title="MOV (QuickTime Video)" />
          <Form.Dropdown.Item value="webm" title="WebM (VP9 / Opus — Open Web)" />
          <Form.Dropdown.Item value="mkv" title="MKV (Matroska Video Container)" />
          <Form.Dropdown.Item value="avi" title="AVI (Legacy AVI Video)" />
        </Form.Dropdown>
      )}

      {mode === "gif" && (
        <Form.Dropdown id="fps" title="Frame Rate (FPS)" value={fps} onChange={setFps}>
          <Form.Dropdown.Item value="10" title="10 FPS (Compact Size)" />
          <Form.Dropdown.Item value="15" title="15 FPS (Balanced — Recommended)" />
          <Form.Dropdown.Item value="24" title="24 FPS (Smooth Animation)" />
          <Form.Dropdown.Item value="30" title="30 FPS (Maximum Fluidity)" />
        </Form.Dropdown>
      )}

      {mode === "audio" && (
        <Form.Dropdown id="audioFormat" title="Target Audio Format" value={targetFormat} onChange={setTargetFormat}>
          <Form.Dropdown.Item value="mp3" title="MP3 (Standard Audio)" />
          <Form.Dropdown.Item value="m4a" title="M4A (Apple AAC Audio)" />
          <Form.Dropdown.Item value="wav" title="WAV (Uncompressed PCM Audio)" />
          <Form.Dropdown.Item value="aac" title="AAC (Advanced Audio Coding)" />
          <Form.Dropdown.Item value="flac" title="FLAC (Lossless Audio)" />
        </Form.Dropdown>
      )}

      {result && (
        <Form.Description
          title="Result"
          text={`Processed in ${(result.durationSeconds).toFixed(2)}s\nOutput: ${result.outputs[0]}`}
        />
      )}
    </Form>
  );
}
