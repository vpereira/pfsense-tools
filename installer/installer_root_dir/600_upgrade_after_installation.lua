--
-- pfSense lua download routines.
--
require "socket"

ip = socket.dns.toip("www.pfsense.com")
if not ip then
    return
end

function download (host, file, outputfile)
  local c = socket.connect(host, 80)
  local pr
  local calcprog = 1
  if not c then
    -- error connecting to target
    -- lets return nil
    return
  end
  pr = App.ui:new_progress_bar{
      title = _("Downloading Updates...")
  }
  pr:start()  
  local count = 0    -- counts number of bytes read
  c:send("GET " .. file .. " HTTP/1.0\r\n\r\n")
  handle = io.open(outputfile, "wb")
  while 1 do
        l = c:receive()
        if l == "" then break end
  end  
  while true do
    local s, status = c:receive(100)
    if s then
        handle:write(s)
    end
    if status == "closed" then break end
    if s then
        count = count + string.len(s)
        calcprog = count / 190000
        pr:set_amount(calcprog)
        pr:update()
    end
  end
  c:close()
  handle:close()
  -- return the number of bytes read
  pr:stop()
  return count
end

return {
    id = "upgrade_pfsense",
    name = _("Upgrade pfSense"),
    effect = function(step)
	local response = App.ui:present{
	    name = _("Upgrade pfSense?"),
	    short_desc =
	        _("Internet connection deteceted.\n\n" ..
                  "Would you like to upgrade pfSense to the latest version?"),
	    actions = {
		{
		    id = "ok",
		    name = _("Upgrade pfSense")
		},
		{
		    id = "cancel",
		    accelerator = "ESC",
		    name = _("No thanks")
		}
	    }
	}
	if response.action_id == "ok" then
                --- lets upgrade pfsense!
                host = "www.pfSense.com"
                file = "/updates/latest.tgz"
		status = 0
                outputfile = "/FreeSBIE/mnt/usr/latest.tgz"
                status = download(host, file, outputfile)
		if not status then
		    App.ui:inform(
			_("There was an error connecting to the pfSense update site." ..
			  "Please upgrade pfSense manually from the webConfigurator"))
		    return step:next()
		end
		file = "/updates/latest.tgz.md5"
		outputfile = "/FreeSBIE/mnt/usr/latest.tgz.md5"
		status = download(host, file, outputfile)
		if not status then
		    App.ui:inform(
			_("There was an error connecting to the pfSense update site." ..
			  "Please upgrade pfSense manually from the webConfigurator"))
		    return step:next()
		end
		-- XXX: Verify MD5 before proceeding
                cmds = CmdChain.new()
                cmds:add("tar xzpf /FreeSBIE/mnt/usr/latest.tgz -U -C /FreeSBIE/mnt/")
                -- XXX: integrate progress bar somehow for execute command
                cmds:execute()
        end        
	-- success!
        return step:next()
    end
}
