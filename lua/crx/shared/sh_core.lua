-- Construct CRX Class
CRX = CRX or CRXClass()

-- Construct Category Class
CRXCategory = CRXCategoryClass()

-- Construct Command Class
CRXCommand = CRXCommandClass()

-- Construct Database Class
CRXDatabase = CRXDatabaseClass()

-- Construct Net Class
CRXNet = CRXNetClass()

-- Construct GUI Class
if CLIENT then
	CRXGUI = CRXGUIClass()
end