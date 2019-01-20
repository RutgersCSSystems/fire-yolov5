/* -*- Mode: C; tab-width: 2; c-basic-offset: 2; indent-tabs-mode: nil -*- */
#include "mem_config.h"
#include <stdlib.h>
#include <inttypes.h>
#include <time.h>
#include <stdbool.h>
#include <string.h>
#include "storage.h"
#include "hoard/src/heaplayers/wrappers/gnuwrapper.h"
//#define _USE_DIRECTED_ALLOC

struct list_entry {
  struct item item;
  struct list_entry *next;
  struct list_entry *prev;
};

static struct list_entry *root;
static uint64_t cas;

bool initialize_storage(void)
{
  return true;
}

void shutdown_storage(void)
{
  /* Do nothing */
}

void put_item(struct item* item)
{
  struct list_entry* entry= (struct list_entry*)item;

  update_cas(item);

  if (root == NULL)
  {
    entry->next= entry->prev= entry;
  }
  else
  {
    entry->prev= root->prev;
    entry->next= root;
    entry->prev->next= entry;
    entry->next->prev= entry;
  }

  root= entry;
}

struct item* get_item(const void* key, size_t nkey)
{
  struct list_entry *walker= root;

  if (root == NULL)
  {
    return NULL;
  }

  do
  {
    if (((struct item*)walker)->nkey == nkey &&
        memcmp(((struct item*)walker)->key, key, nkey) == 0)
    {
      return (struct item*)walker;
    }
    walker= walker->next;
  } while (walker != root);

  return NULL;
}

struct item* create_item(const void* key, size_t nkey, const void* data,
                         size_t size, uint32_t flags, time_t exp)
{

#ifdef _USE_DIRECTED_ALLOC
  fprintf(stdout,"using _USE_DIRECTED_ALLOC \n");	
  struct item* ret= (struct item*)xxmalloc(1 *sizeof(struct list_entry));
#else
  struct item* ret= (struct item*)calloc(1, sizeof(struct list_entry));
#endif

  if (ret != NULL)
  {

#ifdef _USE_DIRECTED_ALLOC
	ret->key= xxmalloc(nkey);
#else
    ret->key= malloc(nkey);
#endif

    if (size > 0)
    {
#ifdef _USE_DIRECTED_ALLOC
      ret->key= xxmalloc(nkey);
#else
      ret->data= malloc(size);
#endif
    }

    if (ret->key == NULL || (size > 0 && ret->data == NULL))
    {
#ifdef _USE_DIRECTED_ALLOC
	xxfree(ret->key);
    xxfree(ret->data);
	xxfree(ret); 	
#else
      free(ret->key);
      free(ret->data);
      free(ret);
#endif
      return NULL;
    }

    memcpy(ret->key, key, nkey);
    if (data != NULL)
    {
      memcpy(ret->data, data, size);
    }

    ret->nkey= nkey;
    ret->size= size;
    ret->flags= flags;
    ret->exp= exp;
  }

  return ret;
}

bool delete_item(const void* key, size_t nkey)
{
  struct item* item= get_item(key, nkey);
  bool ret= false;

  if (item)
  {
    /* remove from linked list */
    struct list_entry *entry= (struct list_entry*)item;

    if (entry->next == entry)
    {
      /* Only one object in the list */
      root= NULL;
    }
    else
    {
      /* ensure that we don't loose track of the root, and this will
       * change the start position for the next search ;-) */
      root= entry->next;
      entry->prev->next= entry->next;
      entry->next->prev= entry->prev;
    }

#ifdef _USE_DIRECTED_ALLOC
	xxfree(ret->key);
    xxfree(ret->data);
	xxfree(ret); 	
#else
    free(ret->key);
    free(ret->data);
    free(ret);
#endif

    ret= true;
  }

  return ret;
}

void flush(uint32_t /* when */)
{
  /* remove the complete linked list */
  if (root == NULL)
  {
    return;
  }

  root->prev->next= NULL;
  while (root != NULL)
  {
    struct item* tmp= (struct item*)root;
    root= root->next;
#ifdef _USE_DIRECTED_ALLOC
	xxfree(tmp->key);
    xxfree(tmp->data);
	xxfree(tmp); 	
#else
    free(tmp->key);
    free(tmp->data);
    free(tmp);
#endif
  }
}

void update_cas(struct item* item)
{
  item->cas= ++cas;
}

void release_item(struct item* /* item */)
{
}
