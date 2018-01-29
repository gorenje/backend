FROM ruby:2.4.3
WORKDIR /usr/src/app
ENV LANG C.UTF-8
COPY Gemfile .
COPY Gemfile.lock .
RUN gem install bundler
RUN bundle config git.allow_insecure true
RUN bundle install --jobs 8 --retry 3
COPY . .
CMD ["foreman", "start", "web"]
