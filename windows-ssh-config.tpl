add-content -path C:/Users/dodo_/.ssh/config -value @'
Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
'@