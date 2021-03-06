﻿using System;
using MixERP.Finance.AppModels;

namespace MixERP.Finance.DAL
{
    public interface IEodPerformer
    {
        event EventHandler<EodEventArgs> NotificationReceived;
        void Perform(string tenant, long loginId);
    }
}