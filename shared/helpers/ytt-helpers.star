load("@ytt:struct", "struct")

def packages_with_configure_db(packages = []):
    l = []
 for p in packages:
     if hasattr(p, "configure_db"):
         if p.configure_db:
             l.append(p)
     end
   end
 end
 return l
end

def packages_without_configure_db(packages = []):
    l = []
 for p in packages:
     if not hasattr(p, "configure_db"):
         l.append(p)
   elif not p.configure_db:
       l.append(p)
   end
 end
 return l
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

helpers = struct.make(
    packages_with_configure_db=packages_with_configure_db,
    packages_without_configure_db=packages_without_configure_db,
    on_windows=on_windows,
    privileged=privileged
)

