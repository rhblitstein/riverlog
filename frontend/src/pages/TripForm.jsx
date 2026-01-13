import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { trips as tripsApi } from '../api/client'
import Layout from '../components/Layout'

function TripForm() {
  const { id } = useParams()
  const isEditing = !!id
  
  const [formData, setFormData] = useState({
    river_name: '',
    section_name: '',
    trip_date: '',
    difficulty: '',
    flow: '',
    flow_unit: 'cfs',
    craft_type: '',
    duration_minutes: '',
    mileage: '',
    notes: '',
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  
  const { token } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (isEditing) {
      fetchTrip()
    }
  }, [id])

  const fetchTrip = async () => {
    try {
      const response = await tripsApi.get(token, id)
      const trip = response.data
      
      setFormData({
        river_name: trip.river_name || '',
        section_name: trip.section_name || '',
        trip_date: trip.trip_date || '',
        difficulty: trip.difficulty || '',
        flow: trip.flow || '',
        flow_unit: trip.flow_unit || 'cfs',
        craft_type: trip.craft_type || '',
        duration_minutes: trip.duration_minutes || '',
        mileage: trip.mileage || '',
        notes: trip.notes || '',
      })
    } catch (err) {
      setError('Failed to fetch trip')
    }
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    const data = {
      river_name: formData.river_name,
      section_name: formData.section_name,
      trip_date: formData.trip_date,
      difficulty: formData.difficulty || null,
      flow: formData.flow ? parseInt(formData.flow) : null,
      flow_unit: formData.flow_unit || null,
      craft_type: formData.craft_type || null,
      duration_minutes: formData.duration_minutes ? parseInt(formData.duration_minutes) : null,
      mileage: formData.mileage ? parseFloat(formData.mileage) : null,
      notes: formData.notes || null,
    }

    try {
      if (isEditing) {
        await tripsApi.update(token, id, data)
      } else {
        await tripsApi.create(token, data)
      }
      navigate('/trips')
    } catch (err) {
      setError(err.message || `Failed to ${isEditing ? 'update' : 'create'} trip`)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Layout>
      <div className="max-w-3xl mx-auto">
        <h2 className="text-3xl font-bold text-gray-900 mb-8">
          {isEditing ? 'Edit Trip' : 'Log New Trip'}
        </h2>

        {error && (
          <div className="bg-red-50 border border-red-200 rounded p-4 mb-6">
            <p className="text-sm text-red-800">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="card space-y-6">
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div className="sm:col-span-2">
              <label htmlFor="river_name" className="block text-sm font-medium text-gray-700 mb-2">
                River Name *
              </label>
              <input
                type="text"
                name="river_name"
                id="river_name"
                required
                className="input"
                value={formData.river_name}
                onChange={handleChange}
              />
            </div>

            <div className="sm:col-span-2">
              <label htmlFor="section_name" className="block text-sm font-medium text-gray-700 mb-2">
                Section Name *
              </label>
              <input
                type="text"
                name="section_name"
                id="section_name"
                required
                className="input"
                value={formData.section_name}
                onChange={handleChange}
              />
            </div>

            <div>
              <label htmlFor="trip_date" className="block text-sm font-medium text-gray-700 mb-2">
                Date *
              </label>
              <input
                type="date"
                name="trip_date"
                id="trip_date"
                required
                className="input"
                value={formData.trip_date}
                onChange={handleChange}
              />
            </div>

            <div>
              <label htmlFor="difficulty" className="block text-sm font-medium text-gray-700 mb-2">
                Difficulty
              </label>
              <input
                type="text"
                name="difficulty"
                id="difficulty"
                placeholder="e.g., III, IV+"
                className="input"
                value={formData.difficulty}
                onChange={handleChange}
              />
            </div>

            <div>
              <label htmlFor="flow" className="block text-sm font-medium text-gray-700 mb-2">
                Flow
              </label>
              <input
                type="number"
                name="flow"
                id="flow"
                className="input"
                value={formData.flow}
                onChange={handleChange}
              />
            </div>

            <div>
              <label htmlFor="flow_unit" className="block text-sm font-medium text-gray-700 mb-2">
                Flow Unit
              </label>
              <select
                name="flow_unit"
                id="flow_unit"
                className="input"
                value={formData.flow_unit}
                onChange={handleChange}
              >
                <option value="cfs">CFS</option>
                <option value="feet">Feet</option>
              </select>
            </div>

            <div>
              <label htmlFor="craft_type" className="block text-sm font-medium text-gray-700 mb-2">
                Craft Type
              </label>
              <input
                type="text"
                name="craft_type"
                id="craft_type"
                placeholder="e.g., kayak, raft"
                className="input"
                value={formData.craft_type}
                onChange={handleChange}
              />
            </div>

            <div>
              <label htmlFor="duration_minutes" className="block text-sm font-medium text-gray-700 mb-2">
                Duration (minutes)
              </label>
              <input
                type="number"
                name="duration_minutes"
                id="duration_minutes"
                className="input"
                value={formData.duration_minutes}
                onChange={handleChange}
              />
            </div>

            <div className="sm:col-span-2">
              <label htmlFor="mileage" className="block text-sm font-medium text-gray-700 mb-2">
                Mileage
              </label>
              <input
                type="number"
                step="0.1"
                name="mileage"
                id="mileage"
                className="input"
                value={formData.mileage}
                onChange={handleChange}
              />
            </div>

            <div className="sm:col-span-2">
              <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-2">
                Notes
              </label>
              <textarea
                name="notes"
                id="notes"
                rows={4}
                className="input"
                value={formData.notes}
                onChange={handleChange}
              />
            </div>
          </div>

          <div className="flex justify-end gap-4 pt-6 border-t-2 border-gray-200">
            <button
              type="button"
              onClick={() => navigate('/trips')}
              className="btn-secondary"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="btn-primary disabled:opacity-50"
            >
              {loading ? 'Saving...' : (isEditing ? 'Update Trip' : 'Create Trip')}
            </button>
          </div>
        </form>
      </div>
    </Layout>
  )
}

export default TripForm