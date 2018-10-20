FROM "node:8.9.0"
RUN yarn global add npm@6.4.1
WORKDIR /usr/src/app
COPY package.json .
COPY package-lock.json .
RUN npm install
COPY . .
CMD ["node", "/usr/src/app/throng.js"]
