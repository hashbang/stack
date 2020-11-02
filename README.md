# #!stack #

<http://github.com/hashbang/stack>

## About ##

At #! we are obsessed with security, privacy, and digital sovereignity.

K8S is a great foundation for self hosting, however most popular practices
recommend using a random hodge podge of third party containers and pod recipies
and complex CI/CD tooling that make it almost impossible to reason about your
software supply chain or hardening standards, as well making you totally at the
mercy of many third parties that might rate limit you or require you to
identify yourself at any time.

Other major reasons experienced infrastructure engineers run screaming from K8S
is that they need a stack they can understand, control, and debug any part of.
Popular K8S infrastructure practices make you simply hope many constantly
changing third party compiled container images, binareis, and services all
continue to play nice on the next update.

We seek to demonstrate the best of both worlds for our own infrastructure in
this repository.

## Design

### Maintainable

* Cached versions of known working images and tools are in-repo via git-lfs
* Any portion of infrastructure can be easily built and tested locally
* All upstream sources defined in one config file for quick global updates
* Every cluster has a local git repo that is always in sync with deployed state

### Predictable

* No third party SaaS is used. We self host git repos, registry, CI/CD, etc.
* Container definitions are in-tree from shared base images, for rapid updates
* Every tool and container image are built locally and deterministically
* Support remote deployments to baremetal or cloud via infra-as-code
* Remote infra will deviate from local infra only via small kustomize overlays

### Hardened

* All production changes must be signed by hardware keys of whitelisted admins
* Service containers are all "FROM scratch" containing only static binaries
* We globally hash lock external supply chains to eliminate external mutation

### Minimal

* Everything is maintained through single makefile and simple scripts
* Everything to deploy from 0 is in respective pods, infra, images folders
* CI/CD is just bare bones scripts, git-shell, and "git push" hooks and timers

## Environments

  | Environment  | Backend          | Status | Access                  |
  |--------------|:----------------:|:------:|:-----------------------:|
  | development  | K3D              | WIP    | Anyone                  |
  | staging      | DigitalOcean K8S | TBD    | Community devs & admins |
  | production   | DigitalOcean K8S | TBD    | Community Admins        |
  | next         | Baremetal K3S    | TBD    | Community Admins        |

## Services

  | Name    | Development           | Staging | Production | Next |
  |---------|:---------------------:|:-------:|:----------:|:----:|
  | health  | http://localhost:2321 | N/A     | N/A        | N/A  |
  | gitea   | http://localhost:2322 | N/A     | N/A        | N/A  |

## Support ##

Please join us on IRC: ircs://irc.hashbang.sh/#!

## Notes ##

Use at your own risk. You might be eaten by a grue.
