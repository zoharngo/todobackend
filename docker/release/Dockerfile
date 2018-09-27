FROM 2251985/todobackend-base:latest
MAINTAINER Zohar Nyego <zoharngo@gmail.com>

# Copy application artifacts
COPY target /wheelhouse

# Add test entrypoint script
COPY scripts/release.sh /usr/local/bin/release.sh
COPY scripts/wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/release.sh

# Install application
RUN . /appenv/bin/activate && \
    pip install --no-index -f /wheelhouse todobackend && \
    rm -rf /wheelhouse

# Set defaults for entrypoint and command string
ENTRYPOINT ["release.sh"]