if [[ -z $LEVER_KUBECONFIG ]]; then
        echo "LEVER_KUBECONFIG must be set"
        exit 1
fi

readonly REGISTRY_HOST=${REGISTRY_HOST:-"harbor-repo.vmware.com"}
readonly REGISTRY_PROJECT=${REGISTRY_PROJECT:-'ryankilroy/package-for-carto-lever'}
readonly PACKAGE_GIT_COMMIT=${PACKAGE_GIT_COMMIT:-$(git rev-parse HEAD)}
readonly PACKAGE_VERSION=${PACKAGE_VERSION:-$(git describe --tags --abbrev=0)}

echo "REGISTRY_HOST: $REGISTRY_HOST"
echo "REGISTRY_PROJECT: $REGISTRY_PROJECT"
echo "PACKAGE_GIT_COMMIT: $PACKAGE_GIT_COMMIT"
echo "PACKAGE_VERSION: $PACKAGE_VERSION"

ytt -f build-templates/kbld-config.yaml -f build-templates/values-schema.yaml -v build.registry_host=${REGISTRY_HOST} -v build.registry_project=${REGISTRY_PROJECT} > kbld-config.yaml
ytt -f build-templates/package-build.yml -f build-templates/values-schema.yaml -v build.registry_host=${REGISTRY_HOST} -v build.registry_project=${REGISTRY_PROJECT} > package-build.yml
ytt -f build-templates/package-resources.yml -f build-templates/values-schema.yaml > package-resources.yml

export LEVER_BUILD_ID=$(leverctl request package create \
  --kubeconfig <(printf "${LEVER_KUBECONFIG}") \
  --git-branch unused \
  --git-commit ${PACKAGE_GIT_COMMIT} \
  --git-url https://github.com/ryankilroy/package-for-cartographer.git \
  --name-prefix package-for-carto-lever \
  --package-build package-build.yml \
  --package-version ${PACKAGE_VERSION}\
  --imgpkg-bundle ${REGISTRY_HOST}/${REGISTRY_PROJECT}/imgpkg-bundle:latest)

echo "export CURRENT_LEVER_BUILD=$(echo $LEVER_BUILD_ID | grep "Created request" | awk '{print $3}')"