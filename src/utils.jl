function upgradeToBot(token = token)
    isempty(token) && error(
        "Need to set the token via `setDefaultToken` or pass it as an argument",
    )
    headers = Dict("Authorization" => "Bearer $token")
    r = HTTP.request(
        "POST",
        "https://lichess.org/api/bot/account/upgrade",
        headers,
        "";
        status_exception = false,
    )
    if r.status != 200
        @warn(r.status)
        @warn(String(r.body))
        @warn "Couldn't convert account"
    else
        @info("Successfully upgraded account to Bot account")
    end
end

function setDefaultToken!(tok)
    global token, defaultHeader
    token = tok
    defaultHeader = Dict("Authorization" => "Bearer $token")
    myId =
        isempty(token) ? "" :
        JSON.parse(String(HTTP.get(baseUrl * "/account", defaultHeader).body))["id"]
    nothing
end
