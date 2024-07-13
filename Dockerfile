FROM node:lts-alpine AS base

# Setup env variabless for yarn and nextjs
# https://nextjs.org/telemetry
ENV NEXT_TELEMETRY_DISABLED=1 NODE_ENV=production YARN_VERSION=4.3.1

# update dependencies, add libc6-compat and dumb-init to the base image
RUN apk update && apk upgrade && apk add --no-cache libc6-compat && apk add dumb-init
# install and use yarn 4.x
RUN corepack enable && corepack prepare yarn@${YARN_VERSION}

# Install dependencies only when needed
FROM base AS builder
RUN apk update
RUN apk add --no-cache libc6-compat
# Set working directory
WORKDIR /app
RUN yarn global add turbo
COPY . .
RUN turbo prune web --docker

# Add lockfile and package.json's of isolated subworkspace
FROM base AS installer
RUN apk update
RUN apk add --no-cache libc6-compat
WORKDIR /app

# First install the dependecies (as they change less often)
COPY .gitignore .gitignore
COPY --from=builder /app/out/json/ .
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
RUN yarn install

# Build the project
COPY --from=builder /app/out/full/ .
COPY turbo.json turbo.json

# Add `ARG` instructions below if you need `NEXT_PUBLIC_` variables
# then put the value on your fly.toml
# Example:
# ARG NEXT_PUBLIC_SOMETHING

# Uncomment and use build args to enable remote caching
# ARG TURBO_TEAM
# ENV TURBO_TEAM=$TURBO_TEAM

# ARG TURBO_TOKEN
# ENV TURBO_TOKEN=$TURBO_TOKEN

# Build the app (in standalone mode based on next.config.js with turborepo)
RUN yarn turbo run build --filter=web

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

# add the user and group we'll need in our final image
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

COPY --from=installer /app/apps/web/next.config.mjs .
COPY --from=installer /app/apps/web/package.json .

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
# copy the standalone folder inside the .next folder generated from the build process
COPY --from=installer --chown=nextjs:nodejs /app/apps/web/.next/standalone ./
# copy the static folder inside the .next folder generated from the build process
COPY --from=installer --chown=nextjs:nodejs /app/apps/web/.next/static ./apps/web/.next/static
# copy the public folder from the project as this is not included in the build process
COPY --from=installer --chown=nextjs:nodejs /app/apps/web/public/ ./apps/web/public

EXPOSE 3000
ENV PORT 3000

CMD ["dumb-init", "node", "apps/web/server.js"]