import { useState, useEffect } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { trips as tripsApi } from '../api/client'
import Layout from '../components/Layout'

function Trips() {
  const [trips, setTrips] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  
  const { token } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    fetchTrips()
  }, [])

  const fetchTrips = async () => {
    try {
      const response = await tripsApi.list(token)
      setTrips(response.data.trips || [])
    } catch (err) {
      setError(err.message || 'Failed to fetch trips')
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (tripId) => {
    if (!window.confirm('Are you sure you want to delete this trip?')) {
      return
    }

    try {
      await tripsApi.delete(token, tripId)
      setTrips(trips.filter(t => t.id !== tripId))
    } catch (err) {
      alert('Failed to delete trip')
    }
  }

  // Calculate stats
  const totalMiles = trips.reduce((sum, trip) => sum + (trip.mileage || 0), 0)
  const totalTrips = trips.length
  const uniqueRivers = new Set(trips.map(t => t.river_name)).size

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center py-20">
          <p className="text-gray-600">Loading...</p>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      {/* Title */}
      <div className="text-center mb-12">
        <h2 className="text-4xl font-bold text-gray-900 mb-2">River Log</h2>
        <p className="text-gray-600">Every river mile, flip, and swim</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-6 mb-12">
        <div className="stat-box">
          <div className="stat-number">{totalMiles.toFixed(0)}</div>
          <div className="stat-label">Total Miles</div>
        </div>
        <div className="stat-box">
          <div className="stat-number">{totalTrips}</div>
          <div className="stat-label">Total Trips</div>
        </div>
        <div className="stat-box">
          <div className="stat-number">{uniqueRivers}</div>
          <div className="stat-label">Rivers</div>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-4 mb-6">
          <p className="text-sm text-red-800">{error}</p>
        </div>
      )}

      {trips.length === 0 ? (
        <div className="text-center py-20 card">
          <div className="text-6xl mb-4">🚣</div>
          <p className="text-gray-700 text-lg mb-6">No trips logged yet</p>
          <Link to="/trips/new" className="btn-primary inline-block">
            Log Your First Trip
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
        {trips.map((trip) => (
            <div
            key={trip.id}
            className="card cursor-pointer"
            onClick={() => navigate(`/trips/${trip.id}`)}
            >
            <div className="flex items-start justify-between">
                <div className="flex-1">
                <div className="flex items-baseline gap-4 mb-2">
                    <span className="text-sm text-gray-600">
                    {new Date(trip.trip_date).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric'
                    })}
                    </span>
                    <h3 className="text-xl font-bold text-gray-900">
                    {trip.river_name}
                    </h3>
                </div>
                <p className="text-gray-700 mb-3">{trip.section_name}</p>
                
                <div className="flex items-center gap-6 text-sm text-gray-600">
                    {trip.flow && (
                    <span>{trip.flow} {trip.flow_unit || 'cfs'}</span>
                    )}
                    {trip.mileage && (
                    <span className="text-blue-600 font-semibold">{trip.mileage} mi</span>
                    )}
                    {trip.difficulty && (
                    <span className="px-2 py-1 bg-gray-900 text-white text-xs font-bold rounded">
                        {trip.difficulty}
                    </span>
                    )}
                    {trip.craft_type && (
                    <span className="capitalize">{trip.craft_type}</span>
                    )}
                </div>
                </div>
                
                <div className="flex gap-2 ml-4">
                <Link
                    to={`/trips/${trip.id}/edit`}
                    className="btn-secondary"
                    onClick={(e) => e.stopPropagation()}
                >
                    Edit
                </Link>
                <button
                    onClick={(e) => {
                    e.stopPropagation()
                    handleDelete(trip.id)
                    }}
                    className="btn-danger"
                >
                    Delete
                </button>
                </div>
            </div>
            </div>
        ))}
        </div>
      )}
    </Layout>
  )
}

export default Trips