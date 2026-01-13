import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

function Layout({ children, showHeader = true }) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {showHeader && (
        <nav className="bg-white border-b border-gray-200">
          <div className="max-w-6xl mx-auto px-8">
            <div className="flex justify-between items-center h-16">
              <div className="flex items-center space-x-8">
                <Link to="/trips" className="text-xl font-bold text-gray-900 hover:text-gray-700">
                  RiverLog
                </Link>
                {user && (
                  <span className="text-sm text-gray-500">
                    {user.first_name || user.email}
                  </span>
                )}
              </div>
              <div className="flex items-center space-x-4">
                <Link
                  to="/trips/new"
                  className="px-4 py-2 bg-gray-900 text-white rounded hover:bg-gray-800 transition-colors text-sm font-medium"
                >
                  + Log Trip
                </Link>
                <button
                  onClick={handleLogout}
                  className="text-gray-600 hover:text-gray-900 transition-colors text-sm"
                >
                  Logout
                </button>
              </div>
            </div>
          </div>
        </nav>
      )}
      <main className="max-w-6xl mx-auto px-8 py-12">
        {children}
      </main>
    </div>
  )
}

export default Layout