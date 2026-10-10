import React, { useState } from "react";
import { Form, ActionPanel, Action, showToast, Toast, open } from "@raycast/api";
import { mergePDFs, MorphConversionResult } from "./morph-bridge";

export default function Command() {
  const [selectedFiles, setSelectedFiles] = useState<string[]>([]);
  const [outputName, setOutputName] = useState<string>("merged-document.pdf");
  const [result, setResult] = useState<MorphConversionResult | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function handleSubmit() {
    if (selectedFiles.length < 2) {
      await showToast({ style: Toast.Style.Failure, title: "Please select at least 2 PDF documents" });
      return;
    }

    setIsLoading(true);
    const toast = await showToast({ style: Toast.Style.Animated, title: `Merging ${selectedFiles.length} PDFs locally...` });

    try {
      const res = await mergePDFs(selectedFiles, outputName.trim() || undefined);
      setResult(res);
      setIsLoading(false);
      toast.style = Toast.Style.Success;
      toast.title = `Merged ${selectedFiles.length} documents!`;
    } catch (err: any) {
      setIsLoading(false);
      toast.style = Toast.Style.Failure;
      toast.title = "Merge failed";
      toast.message = String(err);
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Merge PDFs with Morph" onSubmit={handleSubmit} />
          {result?.outputs[0] && (
            <Action title="Open Merged Document" onAction={() => open(result.outputs[0])} />
          )}
        </ActionPanel>
      }
    >
      <Form.FilePicker
        id="files"
        title="Select PDF Documents"
        canChooseDirectories={false}
        onChange={setSelectedFiles}
      />

      <Form.TextField
        id="outputName"
        title="Output Filename"
        placeholder="merged-document.pdf"
        value={outputName}
        onChange={setOutputName}
      />

      {result && (
        <Form.Description
          title="Result"
          text={`Merged into ${result.outputs[0]} (${(result.outputSize / 1024).toFixed(0)} KB)`}
        />
      )}
    </Form>
  );
}
