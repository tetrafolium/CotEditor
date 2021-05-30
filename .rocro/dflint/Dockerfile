FROM node:lts-alpine AS dockerfilelint-task

### Install golang ...
RUN apk add --update --no-cache git go && \
    echo "+++ $(git version)" && \
    echo "+++ $(go version)"

ENV GOBIN="$GOROOT/bin" \
    GOPATH="/.go" \
    PATH="${GOPATH}/bin:/usr/local/go/bin:$PATH"

### Install dockerfilelint ...
RUN npm install -g dockerfilelint && \
    echo "+++ dockerfilelint $(dockerfilelint --version)"

ENV REPOPATH="github.com/tetrafolium/CotEditor" \
    TOOLPATH="github.com/tetrafolium/inspecode-tasks"
ENV REPODIR="${GOPATH}/src/${REPOPATH}" \
    TOOLDIR="${GOPATH}/src/${TOOLPATH}"

### Get inspecode-tasks tool ...
RUN go get -u "${TOOLPATH}" || true

ARG OUTDIR
ENV OUTDIR="${OUTDIR:-"/.reports"}"

RUN mkdir -p "${REPODIR}" "${OUTDIR}"
COPY . "${REPODIR}"
WORKDIR "${REPODIR}"

### Run dockerfilelint ...
RUN ( find . -type f -name '*Dockerfile' -print0 | xargs -0 dockerfilelint --output json ) \
        > "${OUTDIR}/dockerfilelint.json" || true
RUN ls -la "${OUTDIR}"

### Convert dockerfilelint JSON to SARIF ...
RUN go run "${TOOLDIR}/dockerfilelint/cmd/main.go" "${REPOPATH}" \
        < "${OUTDIR}/dockerfilelint.json" \
        > "${OUTDIR}/dockerfilelint.sarif"
RUN ls -la "${OUTDIR}"
