local tanka = import 'github.com/grafana/jsonnet-libs/tanka-util/main.libsonnet';
local helm = tanka.helm.new(std.thisFile);
local k = import 'ksonnet-util/kausal.libsonnet';

{
  local _config = {
    name: 'argo-cd',
    repo_server_service_account: 'argo-cd-demo-repo-server',
  },
  local policyRule = $.rbac.v1beta1.policyRule,

  rbac: k.rbac(self._config.repo_server_service_account, [policyRule.new() +
      policyRule.withApiGroups('*') +
      policyRule.withResources(['*']) +
      policyRule.withVerbs(['*']),], "default"),

  argo_cd: helm.template('argo-cd', './charts/argo-cd', {
    values: {
      server: {
        extraArgs: [
          '--disable-auth',
          '--insecure',

        ],
        config: {
          configManagementPlugins: std.manifestYamlDoc(
            [
              {
                name: 'tanka',
                init: {
                  command: [
                    'sh',
                    '-c',
                  ],
                  args: [
                    'jb install',
                  ],
                },
                generate: {
                  command: [
                    'sh',
                    '-c',
                  ],
                  args: [
                    'tk show environments/${TK_ENV} --dangerous-allow-redirect ${EXTRA_ARGS} --ext-str APP_NAME=${ARGOCD_APP_NAME} --ext-str APP_NAMESPACE=${ARGOCD_APP_NAMESPACE} --ext-str APP_REVISION=${ARGOCD_APP_REVISION}',
                  ],
                },
              },
            ],

          ),
        },
      },
      repoServer: {
        serviceAccount: {
          name: _config.repo_server_service_account,
        },
        volumes: [
          {
            name: 'custom-tools',
            emptyDir: {},
          },
        ],
        initContainers: [
          {
            name: 'download-tools',
            image: 'curlimages/curl',
            command: [
              'sh',
              '-c',
            ],
            args: [
              'curl -Lo /custom-tools/jb https://github.com/jsonnet-bundler/jsonnet-bundler/releases/latest/download/jb-linux-amd64 && curl -Lo /custom-tools/tk https://github.com/grafana/tanka/releases/download/v0.20.0/tk-linux-amd64 && chmod +x /custom-tools/tk && chmod +x /custom-tools/jb',
            ],
            volumeMounts: [
              {
                mountPath: '/custom-tools',
                name: 'custom-tools',
              },
            ],
          },
        ],
        volumeMounts: [
          {
            mountPath: '/usr/local/bin/jb',
            name: 'custom-tools',
            subPath: 'jb',
          },
          {
            mountPath: '/usr/local/bin/tk',
            name: 'custom-tools',
            subPath: 'tk',
          },
        ],
      },
    },
  }),
}
