import React from 'react'
import { Button, Card, CardBody, CardFooter, Spacer } from '@nextui-org/react'
import type { TMagicFormPageProps } from 'types/magic-form'
import PageTitle from '../common/PageTitle'

/**
 * Component that renders the Magic Forms Page.
 * @constructor
 */
const MagicFormsPage: React.FC<
  LiveReactComponentProps<TMagicFormPageProps>
> = ({ props: { magic_forms }, pushEvent }) => {
  const handleDelete = (id: string) => {
    pushEvent('react.delete_magic_form', {
      magic_form_id: id,
    })
  }

  const handleUpdate = (id: string) => {
    window.location.href = `/magic-forms/${id}/editor`
  }

  const copyMagicFormUrlToClipboard = (id: string) => {
    const url = `https://app.plomb.ai/magic-forms/${id}`
    navigator.clipboard.writeText(url)
  }

  const openDeleteConfirmationModal = (id: string) => {
    if (window.confirm('Are you sure you want to delete this magic form?')) {
      handleDelete(id)
    }
  }

  const handleCreateMagicForm = () => {
    pushEvent('react.create_magic_form', {})
  }

  return (
    <>
      <PageTitle title='Magic Forms' icon='fluent:form-sparkle-20-filled' />
      <div className='flex justify-end'>
        <Button
          color='primary'
          variant='solid'
          onPress={() => handleCreateMagicForm()}
        >
          Create Magic Form
        </Button>
      </div>
      <div className='mt-2 grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4'>
        {magic_forms.map((form) => (
          <Card key={form.id} fullWidth shadow='sm' isHoverable>
            <CardBody className='flex items-center justify-center'>
              <h3 className='text-lg font-bold'>{form.name}</h3>
              <div className='flex justify-center'>
                <p className='flex items-center'>
                  <iconify-icon
                    icon='iconamoon:eye'
                    width='16'
                    height='16'
                    className='mr-1'
                  />
                  <span className='ml-1'>{form.views_count}</span>
                </p>
                <Spacer x={2} />
                <p className='flex items-center'>
                  <iconify-icon
                    icon='bxs:cog'
                    width='16'
                    height='16'
                    className='mr-1'
                  />
                  <span className='ml-1'>{form.submissions_count}</span>
                </p>
              </div>
            </CardBody>
            <CardFooter className='justify-between'>
              <Button
                color='primary'
                variant='solid'
                onPress={() => handleUpdate(form.id)}
              >
                Edit
              </Button>
              <Button
                color='secondary'
                variant='solid'
                onPress={() => copyMagicFormUrlToClipboard(form.id)}
              >
                Copy Link
              </Button>
              <Button
                color='danger'
                variant='solid'
                onPress={() => openDeleteConfirmationModal(form.id)}
              >
                Delete
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>
    </>
  )
}

export default MagicFormsPage
