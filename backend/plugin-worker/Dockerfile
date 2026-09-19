FROM node:20-alpine
WORKDIR /app
RUN addgroup -S auren && adduser -S auren -G auren
COPY package.json ./
COPY src ./src
RUN chown -R auren:auren /app
USER auren
ENV NODE_ENV=production
CMD ["node","src/worker.js"]