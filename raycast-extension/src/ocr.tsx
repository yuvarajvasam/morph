import React, { useState } from "react";
import { Form, ActionPanel, Action, showToast, Toast, open } from "@raycast/api";
import { extractTextOCR, inspectFile, MorphFileInfo, MorphConversionResult } from "./morph-bridge";

export default function Command() {
  const [selectedFile, setSelectedFile] = useState<string>("");
  const [isSearchablePdf, setIsSearchablePdf] = useState<boolean>(false);
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
      await showToast({ style: Toast.Style.Failure, title: "Please choose an image or PDF" });
      return;
    }

    setIsLoading(true);
    const toast = await showToast({
      style: Toast.Style.Animated,
      title: isSearchablePdf ? "Creating Searchable PDF..." : "Extracting Text with Apple Vision..."
    });

    try {
      const res = await extractTextOCR(selectedFile, isSearchablePdf);
      setResult(res);
      setIsLoading(false);
      toast.style = Toast.Style.Success;
      toast.title = isSearchablePdf ? "Searchable PDF Created!" : "Text Extracted!";
    } catch (err: any) {
      setIsLoading(false);
      toast.style = Toast.Style.Failure;
      toast.title = "OCR Failed";
      toast.message = String(err);
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Recognize Text with Apple Vision" onSubmit={handleSubmit} />
          {result?.outputs[0] && (
            <Action title="Open Output Document" onAction={() => open(result.outputs[0])} />
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
          title="Source File"
          text={`${fileInfo.filename} (${fileInfo.formattedSize})`}
        />
      )}

      <Form.Checkbox
        id="searchable"
        label="Generate Searchable PDF (embeds invisible text layer)"
        value={isSearchablePdf}
        onChange={setIsSearchablePdf}
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
