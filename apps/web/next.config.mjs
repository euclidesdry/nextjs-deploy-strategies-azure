import path, { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    transpilePackages: ["@repo/ui"],
    output: "standalone",
    experimental: {
        outputFileTracingRoot: path.join(__dirname, "../../"),
    },
};

export default nextConfig;
