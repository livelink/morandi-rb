FROM ruby:2.4-slim

LABEL Name=morandirb Version=0.0.1

RUN apt-get update && apt-get install -yyq --no-install-recommends \
  build-essential \
  libglib2.0-dev \
  libgtk2.0-dev \
  libgdk-pixbuf2.0-dev \
  libtiff5-dev \
  imagemagick \
  liblcms2-utils \
  && apt-get clean \
  && rm -rf /va/lib/apt/lists/*

COPY Gemfile* /app/
WORKDIR /app/
RUN bundle config --local gemfile Gemfile.docker
RUN bundle install
COPY . /app

CMD ["bundle", "exec", "guard"]
