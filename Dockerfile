FROM ruby:2.5-slim

LABEL Name=morandirb Version=0.0.1

RUN apt-get update && apt-get install -y \
  git \
  build-essential \
  libglib2.0-dev \
  libgtk2.0-dev \
  libgdk-pixbuf2.0-dev \
  libtiff5-dev

# throw errors if Gemfile has been modified since Gemfile.lock
# RUN bundle config --global frozen 1

WORKDIR /app
COPY . /app

# Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
RUN gem install bundler

RUN bundle install

EXPOSE 3000

CMD ["bundle", "exec", "rspec"]
