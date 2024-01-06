-- [DONE] Register custom usergroups with CAMI.RegisterUsergroup (not user/admin/superadmin) 

-- [DONE] Register the removal of custom usergroups with CAMI.UnregisterUsergroup.

-- Listen to other admin mods creating usergroups with the CAMI.OnUsergroupRegistered and CAMI.OnUsergroupUnregistered hooks
    -- Your admin mod might load after others. When loading, check if new usergroups were created earlier with the CAMI.GetUsergroups() function.

-- [DONE] Call CAMI.SignalUserGroupChanged when a player’s usergroup is changed through your admin mod. Note: this will cause all admin mods to store the new usergroup of the player. As such it should not be called e.g. when simply receiving a player’s usergroup from a database on InitialSpawn. Call it when it is actually changed.

-- Hook to CAMI.PlayerUsergroupChanged so your admin mod does not go out of sync with changes made in other admin mods. Note that this hook is called when CAMI.SignalUserGroupChanged is called. Keep that in mind when calling that function yourself. You can prevent things from being saved twice using the source parameter of the CAMI.SignalUserGroupChanged function.

-- (optional, strongly recommended) Hook to CAMI.OnPrivilegeRegistered, this way you can let your admin mod administrate the permissions added by third party mods.

-- Your admin mod might load after others. When loading, check if new privileges were created earlier with the CAMI.GetPrivileges() function.

-- (optional) Hook to CAMI.OnPrivilegeUnregistered. Some third party mods might want to remove privileges once they have become redundant.

-- (optional, strongly recommended) Hook to CAMI.PlayerHasAccess. This hook allows third party addons to check whether a certain player has a privilege that they have registered. you can probably use existing logic here. Make sure to return true when your admin mod makes a decision.

-- (optional) Hook to CAMI.SteamIDHasAccess if the admin mod supports offline access queries. Make sure to return true when your admin mod makes a decision.

-- DO NOT register the admin mod’s privileges (registering privileges is for third party mods, not for sharing privileges between admin mods)
