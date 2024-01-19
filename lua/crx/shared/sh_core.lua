-- Construct CRX Class
CRX = CRX or CRXClass()

-- Construct Category Class
CRXCategory = CRXCategoryClass()

-- Construct Command Class
CRXCommand = CRXCommandClass()

-- Construct Database Class
local database = CRXDatabaseClass()

CRX:SetDatabase(database)

-- Construct Net Class
local nett = CRXNetClass()

CRX:SetNet(nett)

-- Construct GUI Class
if CLIENT then
	local guii = CRXGUIClass()

	CRX:SetGUI(guii)
end

hook.Run("CRX_Initialized")