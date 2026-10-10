import React, { useState } from "react";
import { Form, ActionPanel, Action, showToast, Toast, open } from "@raycast/api";
import { compressFile, inspectFile, MorphFileInfo, MorphConversionResult } from "./morph-bridge";

export default function Command() {
  const [selectedFile, setSelectedFile] = useState<string>("");
  const [preset, setPreset] = useState<string>("balanced");
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
    } catch (e) {
      showToast({ style: Toast.Style.Failure, title: "Failed to inspect file" });
    }
  }

  async function handleSubmit() {
    if (!selectedFile) {
      await showToast({ style: Toast.Style.Failure, title: "Please choose a file" });
      return;
    }

    setIsLoading(true);
    const toast = await showToast({ style: Toast.Style.Animated, title: "Compressing locally with Morph..." });

    try {
      const res = await compressFile(selectedFile, preset as any);
      setResult(res);
      setIsLoading(false);
      toast.style = Toast.Style.Success;
      toast.title = `Compressed! Saved ${(res.savingsPercentage).toFixed(1)}%`;
    } catch (err: any) {
      setIsLoading(false);
      toast.style = Toast.Style.Failure;
      toast.title = "Compression failed";
      toast.message = String(err);
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Compress with Morph" onSubmit={handleSubmit} />
          {result?.outputs[0] && (
            <Action title="Open Compressed File" onAction={() => open(result.outputs[0])} />
          )}
        </ActionPanel>
      }
    >
      <Form.FilePicker
        id="files"
        title="Select Image or PDF"
        canChooseDirectories={false}
        onChange={handleFileChange}
      />

      {fileInfo && (
        <Form.Description
          title="File Details"
          text={`${fileInfo.format} • ${fileInfo.formattedSize} ${
            fileInfo.width ? `• ${fileInfo.width}×${fileInfo.height}px` : ""
          } ${fileInfo.pageCount ? `• ${fileInfo.pageCount} pages` : ""}`}
        />
      )}

      <Form.Dropdown id="preset" title="Compression Preset" value={preset} onChange={setPreset}>
        <Form.Dropdown.Item value="light" title="Light (Preserve Quality)" />
        <Form.Dropdown.Item value="balanced" title="Balanced (Recommended)" />
        <Form.Dropdown.Item value="maximum" title="Maximum (Aggressive Savings)" />
      </Form.Dropdown>

      {result && (
        <Form.Description
          title="Result"
          text={`Saved ${(result.savingsPercentage).toFixed(1)}% (${(result.bytesSaved / 1024).toFixed(0)} KB) in ${(result.durationSeconds).toFixed(2)}s\nOutput: ${result.outputs[0]}`}
        />
      )}
    </Form>
  );
}
