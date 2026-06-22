load("@ytt:struct", "struct")

def packages_with_configure_db(packages = []):
    result = []
    for package in packages:
        if hasattr(package, "configure_db"):
            if package.configure_db:
                if hasattr(package, "acceptance"):
                    if not package.acceptance:
                        result.append(package)
                    end
                else:
                    result.append(package)
                end
            end
        end
    end
    return result
end

def packages_without_configure_db(packages = []):
    result = []
    for package in packages:
        if not hasattr(package, "configure_db"):
            if hasattr(package, "acceptance"):
                if not package.acceptance:
                    result.append(package)
                end
            else:
                result.append(package)
            end
        elif not package.configure_db:
            if hasattr(package, "acceptance"):
                if not package.acceptance:
                    result.append(package)
                end
            else:
                result.append(package)
            end
        end
    end
    return result
end

def packages_with_a_git_repo(packages = []):
    result = []
    for package in packages:
        if hasattr(package, "same_repo"):
            if not package.same_repo:
                result.append(package)
            end
        else:
            result.append(package)
        end
    end
    return result
end

def on_windows(package):
    if hasattr(package, "on_windows"):
        if package.on_windows:
            return True
        end
    end
    return False
end

def privileged(package):
    if hasattr(package, "privileged"):
        if package.privileged:
            return True
        end
    end
    return False
end

def packages_names_array(packages = [], prefixes = []):
    result = []
    for package in packages:
        if hasattr(package, "name"):
            if package.name:
                if len(prefixes) == 0:
                    result.append(package.name)
                else:
                    for prefix in prefixes:
                        result.append(prefix + package.name)
                    end
                end
            end
        end
    end
    return result
end

def packages_names_array_without_acceptance(packages = [], prefixes = []):
    result = []
    for package in packages:
        if not hasattr(package, "acceptance") or not package.acceptance:
            if hasattr(package, "name"):
                if package.name:
                    if len(prefixes) == 0:
                        result.append(package.name)
                    else:
                        for prefix in prefixes:
                            result.append(prefix + package.name)
                        end
                    end
                end
            end
        end
    end
    return result
end

def on_branch(package):
    if hasattr(package, "on_branch"):
        if package.on_branch:
            return package.on_branch
        end
    end
    return "main"
end

def go_submodule_dirs(package):
    if hasattr(package, "go_submodule_dirs"):
        return package.go_submodule_dirs
    end
    return []
end

def module_base(package):
    if hasattr(package, "module_base"):
        return package.module_base
    end
    return "github.com/{}".format(package.repo)
end

def has_submodule_dirs(package):
    return len(go_submodule_dirs(package)) > 0
end

def packages_with_submodule_dirs(packages = []):
    result = []
    for package in packages:
        if has_submodule_dirs(package):
            result.append(package)
        end
    end
    return result
end

def subdir_index(subdirs, subdir):
    idx = 0
    for s in subdirs:
        if s == subdir:
            return idx
        end
        idx += 1
    end
    return -1
end

def submodule_job_names(packages = [], prefixes = [""]):
    result = []
    for package in packages:
        for subdir in go_submodule_dirs(package):
            for prefix in prefixes:
                result.append("{}{}-{}".format(prefix, package.name, subdir))
            end
        end
    end
    return result
end

helpers = struct.make(
    module_base=module_base,
    packages_with_configure_db=packages_with_configure_db,
    packages_without_configure_db=packages_without_configure_db,
    packages_with_a_git_repo=packages_with_a_git_repo,
    packages_names_array=packages_names_array,
    packages_names_array_without_acceptance=packages_names_array_without_acceptance,
    on_windows=on_windows,
    privileged=privileged,
    on_branch=on_branch,
    go_submodule_dirs=go_submodule_dirs,
    has_submodule_dirs=has_submodule_dirs,
    packages_with_submodule_dirs=packages_with_submodule_dirs,
    subdir_index=subdir_index,
    submodule_job_names=submodule_job_names,
)

