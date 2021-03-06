module Model.ResetPassword where

import Import

import Database.Esqueleto.Internal.Language (From)
import qualified Data.Maybe as Maybe

selectUserIdAndEmailIfVerified :: Text -> DB (Maybe (UserId, Text))
selectUserIdAndEmailIfVerified handle =
    (\case []    -> Nothing
           (x:_) -> let (user_id, memail) = unwrapValues x
                    in if Maybe.isNothing memail
                           then Nothing
                           else Just (user_id, Maybe.fromJust memail)) <$>
    (select $ from $ \u -> do
         where_ $ u ^. UserIdent ==. val handle
             &&. not_ (isNothing $ u ^. UserEmail)
             &&. u ^. UserEmail_verified
         return ( u ^. UserId
                , u ^. UserEmail ))

selectUserIdIfVerified :: Text -> DB (Maybe UserId)
selectUserIdIfVerified email =
    (\case []    -> Nothing
           (x:_) -> Just $ unValue x) <$>
    (select $ from $ \u -> do
         where_ $ u ^. UserEmail_verified
              &&. u ^. UserEmail ==. just (val email)
         return $ u ^. UserId)

fromResetPassword :: From query expr backend (expr (Entity ResetPassword))
                  => UserId -> query ()
fromResetPassword user_id =
    from $ \rp -> where_ $ rp ^. ResetPasswordUser ==. val user_id

deleteFromResetPassword :: UserId -> DB ()
deleteFromResetPassword user_id = delete $ fromResetPassword user_id
