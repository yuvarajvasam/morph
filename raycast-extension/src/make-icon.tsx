import React, { useState } from "react";
import { Form, ActionPanel, Action, showToast, Toast, open } from "@raycast/api";
import { makeAppIcon, inspectFile, MorphFileInfo, MorphConversionResult } from "./morph-bridge";

export default function Command() {
  const [selectedFile, setSelectedFile] = useState<string>("");
  const [extractPng, setExtractPng] = useState<boolean>(false);
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
      if (path.toLowerCase().endsWith(".icns")) {
        setExtractPng(true);
      }
    } catch {
      showToast({ style: Toast.Style.Failure, title: "Failed to inspect file" });
    }
  }

  async function handleSubmit() {
    if (!selectedFile) {
      await showToast({ style: Toast.Style.Failure, title: "Please choose an image or .icns file" });
      return;
    }

    setIsLoading(true);
    const toast = await showToast({
      style: Toast.Style.Animated,
      title: extractPng ? "Extracting PNG from .icns..." : "Building macOS .icns Icon..."
    });

    try {
      const res = await makeAppIcon(selectedFile, extractPng);
      setResult(res);
      setIsLoading(false);
      toast.style = Toast.Style.Success;
      toast.title = extractPng ? "PNG Extracted!" : "App Icon (.icns) Created!";
    } catch (err: any) {
      setIsLoading(false);
      toast.style = Toast.Style.Failure;
      toast.title = "Icon Generation Failed";
      toast.message = String(err);
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title={extractPng ? "Extract PNG" : "Build .icns Icon"} onSubmit={handleSubmit} />
          {result?.outputs[0] && (
            <Action title="Open Output File" onAction={() => open(result.outputs[0])} />
          )}
        </ActionPanel>
      }
    >
      <Form.FilePicker
        id="files"
        title="Select Image / .icns"
        canChooseDirectories={false}
        onChange={handleFileChange}
      />

      {fileInfo && (
        <Form.Description
          title="File Info"
          text={`${fileInfo.filename} • ${fileInfo.formattedSize} ${
            fileInfo.width ? `• ${fileInfo.width}×${fileInfo.height}px` : ""
          }`}
        />
      )}

      <Form.Checkbox
        id="extract"
        label="Extract 1024px PNG from .icns (instead of creating .icns)"
        value={extractPng}
        onChange={setExtractPng}
      />

      {result && (
        <Form.Description
          title="Result"
          text={`Processed in ${(result.durationSeconds).toFixed(2)}s\nOutput: ${result.outputs[0]}`}
        />
      )}
    </Form>
  );
}
