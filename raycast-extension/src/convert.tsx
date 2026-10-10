import React, { useState } from "react";
import { Form, ActionPanel, Action, showToast, Toast, open } from "@raycast/api";
import { convertImage, inspectFile, MorphFileInfo, MorphConversionResult } from "./morph-bridge";

export default function Command() {
  const [selectedFile, setSelectedFile] = useState<string>("");
  const [targetFormat, setTargetFormat] = useState<string>("png");
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
      await showToast({ style: Toast.Style.Failure, title: "Please choose an image file" });
      return;
    }

    setIsLoading(true);
    const toast = await showToast({ style: Toast.Style.Animated, title: `Converting to ${targetFormat.toUpperCase()}...` });

    try {
      const res = await convertImage(selectedFile, targetFormat as any);
      setResult(res);
      setIsLoading(false);
      toast.style = Toast.Style.Success;
      toast.title = `Converted to ${targetFormat.toUpperCase()}!`;
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
          <Action.SubmitForm title="Convert with Morph" onSubmit={handleSubmit} />
          {result?.outputs[0] && (
            <Action title="Open Converted File" onAction={() => open(result.outputs[0])} />
          )}
        </ActionPanel>
      }
    >
      <Form.FilePicker
        id="files"
        title="Select Image"
        canChooseDirectories={false}
        onChange={handleFileChange}
      />

      {fileInfo && (
        <Form.Description
          title="Current Format"
          text={`${fileInfo.format} • ${fileInfo.formattedSize} ${
            fileInfo.width ? `• ${fileInfo.width}×${fileInfo.height}px` : ""
          } ${fileInfo.hasAlpha ? "• Has Alpha Channel" : ""}`}
        />
      )}

      <Form.Dropdown id="format" title="Target Format" value={targetFormat} onChange={setTargetFormat}>
        <Form.Dropdown.Item value="png" title="PNG (Lossless with Alpha)" />
        <Form.Dropdown.Item value="jpg" title="JPEG (Compact)" />
        <Form.Dropdown.Item value="webp" title="WebP (Modern Web Format)" />
        <Form.Dropdown.Item value="heic" title="HEIC (High Efficiency)" />
      </Form.Dropdown>

      {fileInfo?.hasAlpha && targetFormat === "jpg" && (
        <Form.Description
          title="Note"
          text="⚠️ Source has transparency. JPEG does not support alpha, so transparent background will be filled with white."
        />
      )}

      {result && (
        <Form.Description
          title="Result"
          text={`Successfully converted in ${(result.durationSeconds).toFixed(2)}s\nOutput: ${result.outputs[0]}`}
        />
      )}
    </Form>
  );
}
