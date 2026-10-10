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
  category: "image" | "pdf" | "unsupported";
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
