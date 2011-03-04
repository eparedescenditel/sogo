/* MAPIStoreFolder.m - this file is part of SOGo
 *
 * Copyright (C) 2011 Inverse inc
 *
 * Author: Wolfgang Sourdeau <wsourdeau@inverse.ca>
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/* TODO: main key arrays must be initialized */

#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>
#import <NGExtensions/NSObject+Logs.h>
#import <SOGo/SOGoFolder.h>

#import "MAPIStoreContext.h"
#import "MAPIStoreFSMessage.h"
#import "MAPIStoreFSMessageTable.h"
#import "MAPIStoreFolder.h"
#import "MAPIStoreMessage.h"
#import "MAPIStoreTypes.h"
#import "NSString+MAPIStore.h"
#import "SOGoMAPIFSFolder.h"
#import "SOGoMAPIFSMessage.h"

#include <gen_ndr/exchange.h>

#undef DEBUG
#include <mapistore/mapistore.h>
#include <mapistore/mapistore_nameid.h>
// #include <mapistore/mapistore_errors.h>

Class NSExceptionK;

@implementation MAPIStoreFolder

+ (void) initialize
{
  NSExceptionK = [NSException class];
}

+ (id) baseFolderWithURL: (NSURL *) newURL
               inContext: (MAPIStoreContext *) newContext
{
  id newFolder;

  newFolder = [[self alloc] initWithURL: newURL inContext: newContext];
  [newFolder autorelease];

  return newFolder;
}

- (id) init
{
  if ((self = [super init]))
    {
      messageTable = nil;
      messageKeys = nil;
      faiMessageTable = nil;
      faiMessageKeys = nil;
      folderTable = nil;
      folderKeys = nil;
      faiFolder = nil;
      folderURL = nil;
      context = nil;
    }

  return self;
}

- (id) initWithURL: (NSURL *) newURL
         inContext: (MAPIStoreContext *) newContext
{
  if ((self = [self init]))
    {
      context = newContext;
      ASSIGN (folderURL, newURL);
      ASSIGN (faiFolder,
              [SOGoMAPIFSFolder folderWithURL: newURL
                                 andTableType: MAPISTORE_FAI_TABLE]);
    }

  return self;
}

- (void) dealloc
{
  [folderURL release];
  [messageTable release];
  [messageKeys release];
  [faiMessageTable release];
  [faiMessageKeys release];
  [folderTable release];
  [folderKeys release];
  [faiFolder release];
  [super dealloc];
}

- (MAPIStoreContext *) context
{
  if (!context)
    context = [container context];

  return context;
}

- (NSArray *) messageKeys
{
  if (!messageKeys)
    {
      messageKeys = [self childKeysMatchingQualifier: nil
                                    andSortOrderings: nil];
      [messageKeys retain];
    }

  return messageKeys;
}

- (MAPIStoreFSMessageTable *) faiMessageTable
{
  if (!faiMessageTable)
    {
      faiMessageTable = [MAPIStoreFSMessageTable tableForContainer: self];
      [faiMessageTable retain];
    }

  return faiMessageTable;
}

- (NSArray *) faiMessageKeys
{
  if (!faiMessageKeys)
    {
      faiMessageKeys = [faiFolder toOneRelationshipKeys];
      [faiMessageKeys retain];
    }

  return faiMessageKeys;
}

- (MAPIStoreFolderTable *) folderTable
{
  return nil;
}

- (NSArray *) folderKeys
{
  if (!faiMessageKeys)
    faiMessageKeys = [NSArray new];

  return faiMessageKeys;
}

- (void) cleanupCaches
{
  [faiMessageTable cleanupCaches];
  [faiMessageKeys release];
  faiMessageKeys = nil;
  [messageTable cleanupCaches];
  [messageKeys release];
  messageKeys = nil;
  [folderTable cleanupCaches];
  [folderKeys release];
  folderKeys = nil;
}

- (id) lookupChild: (NSString *) childKey
{
  MAPIStoreObject *newChild;
  SOGoObject *msgObject;

  if (childKey)
    {
      [self faiMessageKeys];
      if ([faiMessageKeys containsObject: childKey])
        {
          msgObject = [faiFolder lookupName: childKey
                                 inContext: nil
                                 acquire: NO];
          newChild
            = [MAPIStoreFSMessage mapiStoreObjectWithSOGoObject: msgObject
                                                    inContainer: self];
        }
      else
        {
          msgObject = [sogoObject lookupName: childKey
                                  inContext: nil
                                  acquire: NO];
          if ([msgObject isKindOfClass: NSExceptionK])
            msgObject = nil;
          
          if (msgObject)
            newChild
              = [[self messageClass] mapiStoreObjectWithSOGoObject: msgObject
                                                       inContainer: self];
          else
            newChild = nil;
        }
    }
  else
    newChild = nil;

  return newChild;
}

- (enum MAPISTATUS) getProperty: (void **) data
                        withTag: (enum MAPITAGS) propTag
{
  int rc;

  rc = MAPI_E_SUCCESS;
  switch (propTag)
    {
    case PR_FID:
      /* TODO: incomplete */
      *data = MAPILongValue (memCtx, [self objectId]);
      break;
    case PR_ACCESS: // TODO
      *data = MAPILongValue (memCtx, 0x63);
      break;
    case PR_ACCESS_LEVEL: // TODO
      *data = MAPILongValue (memCtx, 0x01);
      break;
    case PR_PARENT_FID:
      *data = MAPILongLongValue (memCtx, [container objectId]);
      break;
    case PR_ATTR_HIDDEN:
    case PR_ATTR_SYSTEM:
    case PR_ATTR_READONLY:
      *data = MAPIBoolValue (memCtx, NO);
      break;
    case PR_SUBFOLDERS:
      *data = MAPIBoolValue (memCtx, [folderKeys count]);
                             // [[child toManyRelationshipKeys] count] > 0);
      break;
    case PR_CONTENT_COUNT:
      *data = MAPILongValue (memCtx, [messageKeys count]);
      break;
    // case PR_EXTENDED_FOLDER_FLAGS: // TODO: DOUBT: how to indicate the
    //   // number of subresponses ?
    //   binaryValue = talloc_zero(memCtx, struct Binary_r);
    //   *data = binaryValue;
    //   break;
    default:
      rc = [super getProperty: data
                      withTag: propTag];
    }

  return rc;
}

- (MAPIStoreMessage *) _createAssociatedMessage
{
  MAPIStoreMessage *newMessage;
  SOGoMAPIFSMessage *fsObject;
  NSString *newKey;

  newKey = [NSString stringWithFormat: @"%@.plist",
                     [SOGoObject globallyUniqueObjectId]];
  fsObject = [SOGoMAPIFSMessage objectWithName: newKey inContainer: faiFolder];
  newMessage = [MAPIStoreFSMessage mapiStoreObjectWithSOGoObject: fsObject
                                                     inContainer: self];

  
  return newMessage;
}

- (MAPIStoreMessage *) createMessage: (BOOL) isAssociated
{
  MAPIStoreMessage *newMessage;

  if (isAssociated)
    newMessage = [self _createAssociatedMessage];
  else
    newMessage = [self createMessage];

  return newMessage;
}

- (NSString *) createFolder: (struct SRow *) aRow
{
  [self errorWithFormat: @"new folders cannot be created in this context"];

  return nil;
}

/* helpers */

- (NSString *) url
{
  NSString *url;

  if (folderURL)
    url = [folderURL absoluteString];
  else
    url = [NSString stringWithFormat: @"%@/", [super url]];

  return url;
}

- (uint64_t) objectId
{
  uint64_t objectId;

  if (folderURL)
    objectId = [self idForObjectWithKey: nil];
  else
    objectId = [super objectId];

  return objectId;
}

- (uint64_t) idForObjectWithKey: (NSString *) childKey
{
  return [[self context] idForObjectWithKey: childKey
                                inFolderURL: [self url]];
}

/* subclasses */

- (MAPIStoreMessageTable *) messageTable
{
  return nil;
}

- (Class) messageClass
{
  [self subclassResponsibility: _cmd];

  return Nil;
}

- (MAPIStoreMessage *) createMessage
{
  [self subclassResponsibility: _cmd];

  return nil;
}

@end