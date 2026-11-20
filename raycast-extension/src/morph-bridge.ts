import { execFile } from "child_process";
import { promisify } from "util";
import * as fs from "fs";

const execFileAsync = promisify(execFile);

export function getMorphBinaryPath(): string {
  const candidatePaths = [
    "/Applications/Morph.app/Contents/MacOS/morph",
    "/Users/yuvi/Developer/morph/Morph.app/Contents/MacOS/morph",
    "/usr/local/bin/morph",
    "/opt/homebrew/bin/morph"
  ];

  for (const path of candidatePaths) {
    if (fs.existsSync(path)) {
      return path;
    }
  }

  return "morph";
}

export interface MorphFileInfo {
  filename: string;
  fileSize: number;
  formattedSize: string;
  category: "image" | "pdf" | "media" | "office" | "vector" | "data" | "icon" | "unsupported";
  format: string;
  width?: number;
  height?: number;
  pageCount?: number;
  hasAlpha?: boolean;
}

export interface MorphConversionResult {
  originalSize: number;
  outputSize: number;
  bytesSaved: number;
  savingsPercentage: number;
  durationSeconds: number;
  outputs: string[];
  outputWidth?: number;
  outputHeight?: number;
  notes?: string;
}

export interface MorphEngineInfo {
  id: string;
  name: string;
  category: string;
  isNative: boolean;
  isAvailable: boolean;
  path: string;
  version: string;
  supportedConversions: string[];
  installCommand: string;
}

export async function runMorphCLI(args: string[]): Promise<string> {
  const binary = getMorphBinaryPath();
  const { stdout } = await execFileAsync(binary, args);
  return stdout;
}

export async function inspectFile(filePath: string): Promise<MorphFileInfo> {
  const stdout = await runMorphCLI(["info", filePath, "--json"]);
  return JSON.parse(stdout) as MorphFileInfo;
}

export async function compressFile(
  filePath: string,
  preset: "light" | "balanced" | "maximum" = "balanced"
): Promise<MorphConversionResult> {
  const stdout = await runMorphCLI(["compress", filePath, "--preset", preset, "--json"]);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function convertImage(
  filePath: string,
  targetFormat: "jpg" | "png" | "heic" | "webp"
): Promise<MorphConversionResult> {
  const stdout = await runMorphCLI(["convert", filePath, "--to", targetFormat, "--json"]);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function mergePDFs(filePaths: string[], outputFilename?: string): Promise<MorphConversionResult> {
  const args = ["merge", ...filePaths, "--json"];
  if (outputFilename) {
    args.push("--output", outputFilename);
  }
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function extractTextOCR(
  filePath: string,
  searchablePdf = false
): Promise<MorphConversionResult> {
  const args = ["ocr", filePath, "--json"];
  if (searchablePdf) {
    args.push("--searchable");
  }
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function makeAppIcon(
  filePath: string,
  extractPng = false
): Promise<MorphConversionResult> {
  const args = ["icon", filePath, "--json"];
  if (extractPng) {
    args.push("--extract");
  }
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function convertVideo(
  filePath: string,
  targetFormat: string,
  options?: { crf?: string; fps?: number; width?: number }
): Promise<MorphConversionResult> {
  const args = ["video", filePath, "--to", targetFormat, "--json"];
  if (options?.crf) {
    args.push("--crf", options.crf);
  }
  if (options?.fps) {
    args.push("--fps", String(options.fps));
  }
  if (options?.width) {
    args.push("--width", String(options.width));
  }
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function extractAudio(
  filePath: string,
  targetFormat: string
): Promise<MorphConversionResult> {
  const args = ["audio", filePath, "--to", targetFormat, "--json"];
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function convertOffice(
  filePath: string
): Promise<MorphConversionResult> {
  const args = ["office", filePath, "--json"];
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function convertData(
  filePath: string,
  targetFormat: "json" | "plist" | "xml" | "csv",
  pretty = true
): Promise<MorphConversionResult> {
  const args = ["data", filePath, "--to", targetFormat, "--json"];
  if (pretty) {
    args.push("--pretty");
  }
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function stripMetadata(
  filePath: string
): Promise<MorphConversionResult> {
  const args = ["metadata", filePath, "--strip", "--json"];
  const stdout = await runMorphCLI(args);
  return JSON.parse(stdout) as MorphConversionResult;
}

export async function listEngines(): Promise<MorphEngineInfo[]> {
  const stdout = await runMorphCLI(["engines", "--json"]);
  return JSON.parse(stdout) as MorphEngineInfo[];
}
