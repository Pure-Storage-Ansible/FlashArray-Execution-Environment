ARG EE_BASE_IMAGE=registry.redhat.io/ansible-automation-platform-20-early-access/ee-minimal-rhel8:2.0.0-10
ARG EE_BUILDER_IMAGE=registry.redhat.io/ansible-automation-platform-20-early-access/ansible-builder-rhel8:2.0.0-10

FROM $EE_BASE_IMAGE as galaxy
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS=
USER root

ADD _build/ansible.cfg ~/.ansible.cfg

ADD _build /build
WORKDIR /build

RUN ansible-galaxy role install -r requirements.yml --roles-path /usr/share/ansible/roles
RUN ansible-galaxy collection install $ANSIBLE_GALAXY_CLI_COLLECTION_OPTS -r requirements.yml --collections-path /usr/share/ansible/collections

FROM $EE_BUILDER_IMAGE as builder

COPY --from=galaxy /usr/share/ansible /usr/share/ansible

RUN ansible-builder introspect --sanitize --write-bindep=/tmp/src/bindep.txt --write-pip=/tmp/src/requirements.txt
RUN assemble

FROM $EE_BASE_IMAGE
USER root

COPY --from=galaxy /usr/share/ansible /usr/share/ansible

COPY --from=builder /output/ /output/
RUN /output/install-from-bindep && rm -rf /output/wheels
