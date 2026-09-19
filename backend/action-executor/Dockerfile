FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY src ./src
RUN addgroup -S auren && adduser -S auren -G auren && chown -R auren:auren /app
USER auren
ENV NODE_ENV=production
EXPOSE 8080
CMD ["node","src/server.js"]
