if exists('g:autoloaded_db_adapter_sqlserver_azure_ad')
  finish
endif
let g:autoloaded_db_adapter_sqlserver_azure_ad = 1

function! s:server(url) abort
  let host = get(a:url, 'host', '')
  let port = get(a:url, 'port', '')
  if host ==# ''
    return ''
  endif
  return port ==# '' ? host : host . ',' . port
endfunction

function! s:param_bool(params, key) abort
  if !has_key(a:params, a:key)
    return 0
  endif
  let val = tolower(string(a:params[a:key]))
  return index(['1', 'true', 'yes', 'on'], val) >= 0
endfunction

function! s:database_from_path(url) abort
  let path = get(a:url, 'path', '')
  if empty(path)
    return ''
  endif
  " strip leading '/'
  if path[0] ==# '/'
    let path = path[1:]
  endif
  return path
endfunction

function! db#adapter#sqlserver#interactive(url) abort
  let l:url = db#url#parse(a:url)
  let l:params = get(l:url, 'params', {})
  let l:db = s:database_from_path(l:url)

  " ---------- Azure AD / -G mode ----------
  if has_key(l:params, 'azure_ad_auth')
    let l:cmd = ['sqlcmd', '-S', s:server(l:url)]

    " TLS (-N) if encrypt=true/yes/1/on
    if s:param_bool(l:params, 'encrypt')
      call add(l:cmd, '-N')
    endif

    if !empty(l:db)
      call extend(l:cmd, ['-d', l:db])
    endif

    " Azure AD integrated login
    call add(l:cmd, '-G')
    return l:cmd
  endif

  " ---------- Default behaviour ----------
  let l:cmd = ['sqlcmd', '-S', s:server(l:url)]

  " TLS / trustServerCertificate, using params
  if s:param_bool(l:params, 'encrypt')
    call add(l:cmd, '-N')
  endif
  if s:param_bool(l:params, 'trustServerCertificate')
    call add(l:cmd, '-C')
  endif

  " SQL auth if user present, otherwise integrated (-E)
  if has_key(l:url, 'user')
    call extend(l:cmd, ['-U', l:url.user])
    if has_key(l:url, 'password') && !empty(l:url.password)
      call extend(l:cmd, ['-P', l:url.password])
    endif
  endif

  if !empty(l:db)
    call extend(l:cmd, ['-d', l:db])
  endif

  return l:cmd
endfunction

