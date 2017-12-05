FROM "node:8.9.0"
WORKDIR /usr/src/app
COPY package.json .
COPY package-lock.json .
RUN npm install
COPY . .
EXPOSE 5000
CMD ["node", "/usr/src/app/throng.js"]
