FROM ruby:2.7-slim

LABEL Name=morandirb Version=0.0.1

RUN apt-get update && apt-get install -yyq --no-install-recommends \
  build-essential \
  libglib2.0-dev \
  libgtk2.0-dev \
  libgdk-pixbuf2.0-dev \
  imagemagick \
  liblcms2-utils \
  && apt-get clean \
  && rm -rf /va/lib/apt/lists/*

RUN gem update --system 3.4.22

WORKDIR /app
COPY morandi.gemspec Gemfile ./
COPY lib/morandi/version.rb lib/morandi/version.rb
RUN bundle install
COPY . /app

CMD ["bundle", "exec", "guard"]
