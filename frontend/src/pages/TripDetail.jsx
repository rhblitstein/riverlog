import { useState, useEffect } from 'react'
import { useNavigate, useParams, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { trips as tripsApi } from '../api/client'
import Layout from '../components/Layout'

function TripDetail() {
  const { id } = useParams()
  const [trip, setTrip] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  
  const { token } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    fetchTrip()
  }, [id])

  const fetchTrip = async () => {
    try {
      const response = await tripsApi.get(token, id)
      setTrip(response.data)
    } catch (err) {
      setError(err.message || 'Failed to fetch trip')
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async () => {
    if (!window.confirm('Are you sure you want to delete this trip?')) {
      return
    }

    try {
      await tripsApi.delete(token, id)
      navigate('/trips')
    } catch (err) {
      alert('Failed to delete trip')
    }
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center py-20">
          <p className="text-gray-600">Loading...</p>
        </div>
      </Layout>
    )
  }

  if (error || !trip) {
    return (
      <Layout>
        <div className="text-center py-20">
          <p className="text-red-600 mb-4">{error || 'Trip not found'}</p>
          <Link to="/trips" className="btn-secondary">
            Back to Trips
          </Link>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <Link to="/trips" className="btn-secondary">
            ← Back to Trips
          </Link>
          <div className="flex gap-4">
            <Link to={`/trips/${id}/edit`} className="btn-secondary">
              Edit
            </Link>
            <button onClick={handleDelete} className="btn-danger">
              Delete
            </button>
          </div>
        </div>

        <div className="card">
          <div className="flex justify-between items-start mb-8">
            <div>
              <h1 className="text-4xl font-bold text-gray-900 mb-2">{trip.river_name}</h1>
              <p className="text-xl text-gray-700">{trip.section_name}</p>
            </div>
            {trip.difficulty && (
              <span className="px-4 py-2 text-lg font-bold bg-gray-900 text-white rounded">
                {trip.difficulty}
              </span>
            )}
          </div>

          <dl className="grid grid-cols-1 gap-6 sm:grid-cols-2 mb-8">
            <div>
              <dt className="text-sm font-medium text-gray-500 mb-1">Date</dt>
              <dd className="text-lg text-gray-900">
                {new Date(trip.trip_date).toLocaleDateString('en-US', {
                  weekday: 'long',
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric'
                })}
              </dd>
            </div>

            {trip.flow && (
              <div>
                <dt className="text-sm font-medium text-gray-500 mb-1">Flow</dt>
                <dd className="text-lg text-gray-900">
                  {trip.flow} {trip.flow_unit || 'cfs'}
                </dd>
              </div>
            )}

            {trip.craft_type && (
              <div>
                <dt className="text-sm font-medium text-gray-500 mb-1">Craft Type</dt>
                <dd className="text-lg text-gray-900 capitalize">{trip.craft_type}</dd>
              </div>
            )}

            {trip.duration_minutes && (
              <div>
                <dt className="text-sm font-medium text-gray-500 mb-1">Duration</dt>
                <dd className="text-lg text-gray-900">
                  {Math.floor(trip.duration_minutes / 60)}h {trip.duration_minutes % 60}m
                </dd>
              </div>
            )}

            {trip.mileage && (
            <div>
                <dt className="text-sm font-medium text-gray-500 mb-1">Mileage</dt>
                <dd className="text-lg text-blue-600 font-semibold">{trip.mileage} miles</dd>
            </div>
            )}
          </dl>

          {trip.notes && (
            <div className="pt-8 border-t-2 border-gray-200">
              <dt className="text-sm font-medium text-gray-500 mb-3">Notes</dt>
              <dd className="text-gray-700 whitespace-pre-wrap leading-relaxed">{trip.notes}</dd>
            </div>
          )}
        </div>
      </div>
    </Layout>
  )
}

export default TripDetail